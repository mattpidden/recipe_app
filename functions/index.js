const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { GoogleGenAI, Type } = require("@google/genai");

const PROJECT = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
const LOCATION = "europe-west2"; // keep consistent with your app + data residency
let _parseLinePromise;

function getParseLine() {
    if (!_parseLinePromise) {
        _parseLinePromise = import("@recipecloudapp/ingredient-parser").then(
            (m) => m.parseLine
        );
    }
    return _parseLinePromise;
}

exports.parseIngredient = onCall({ region: "europe-west2" }, async (request) => {
    const raw = (request.data?.raw ?? "").toString().trim();
    if (!raw) throw new HttpsError("invalid-argument", "Missing raw ingredient string");

    try {
        const parseLine = await getParseLine();
        const parsed = parseLine(raw);

        if (!parsed || parsed.type !== "item") return { raw };

        return {
            raw,
            quantity:
                typeof parsed.quantity === "number" && Number.isFinite(parsed.quantity)
                    ? parsed.quantity
                    : undefined,
            unit:
                parsed.unit?.display ??
                parsed.unit?.canonical ??
                parsed.unit?.abbr ??
                parsed.unit?.raw,
            item:
                typeof parsed.ingredient === "string" && parsed.ingredient.trim()
                    ? parsed.ingredient.trim()
                    : undefined,
            notes:
                typeof parsed.postNote === "string" && parsed.postNote.trim()
                    ? parsed.postNote.trim()
                    : undefined,
        };
    } catch (err) {
        logger.error("Ingredient parse failed", err);
        return { raw };
    }
});



const ai = new GoogleGenAI({
    vertexai: true,
    project: PROJECT,
    location: "global",
});

function asString(x) {
    return typeof x === "string" ? x : "";
}

function normalizePages(data) {
    const pages = Array.isArray(data?.pages) ? data.pages : [];
    const out = [];

    for (let p = 0; p < pages.length; p++) {
        const page = pages[p] || {};
        const blocks = Array.isArray(page.blocks) ? page.blocks : [];
        const fullText = asString(page.fullText).trim();

        // Prefer blocks if present
        if (blocks.length) {
            for (let b = 0; b < blocks.length; b++) {
                const block = blocks[b] || {};
                const txt = asString(block.text).trim();
                if (!txt) continue;
                out.push({ p, b, text: txt });
            }
            continue;
        }

        // Fallback to fullText if blocks empty
        if (fullText) out.push({ p, b: 0, text: fullText });
    }

    // Absolute fallback if someone sends {text: "..."}
    const topText = asString(data?.text).trim();
    if (out.length === 0 && topText) out.push({ p: 0, b: 0, text: topText });

    return out;
}

function safeJsonParse(text) {
    try {
        return JSON.parse(text);
    } catch (_) {
        return null;
    }
}

exports.parseRecipeFromOcr = onCall(
    { region: LOCATION, timeoutSeconds: 60, memory: "512MiB" },
    async (req) => {
        if (!PROJECT) {
            throw new HttpsError("failed-precondition", "Missing GCP project env.");
        }

        const blocks = normalizePages(req.data);
        if (blocks.length === 0) {
            throw new HttpsError(
                "invalid-argument",
                "No OCR text provided. Send {blocks:[{text:...}]} or {text:'...'}."
            );
        }

        const responseSchema = {
            type: Type.OBJECT,
            properties: {
                title: { type: Type.STRING, nullable: false },
                description: { type: Type.STRING, nullable: true },
                timeMinutes: { type: Type.INTEGER, nullable: true },
                servings: { type: Type.INTEGER, nullable: true },
                tags: {
                    type: Type.ARRAY,
                    items: { type: Type.STRING },
                    nullable: true,
                },
                ingredients: {
                    type: Type.ARRAY,
                    items: {
                        type: Type.OBJECT,
                        properties: {
                            raw: { type: Type.STRING, nullable: false },
                            quantity: { type: Type.NUMBER, nullable: true },
                            unit: { type: Type.STRING, nullable: true },
                            item: { type: Type.STRING, nullable: true },
                            notes: { type: Type.STRING, nullable: true },
                        },
                        required: ["raw"],
                    },
                    nullable: true,
                },
                steps: {
                    type: Type.ARRAY,
                    items: { type: Type.STRING },
                    nullable: true,
                },
                notes: { type: Type.STRING, nullable: true },
                pageNumber: { type: Type.NUMBER, nullable: true },
                // optional debugging fields so you can show “confidence” UI
                confidence: { type: Type.NUMBER, nullable: true },
                warnings: {
                    type: Type.ARRAY,
                    items: { type: Type.STRING },
                    nullable: true,
                },
            },
            required: ["title"],
        };

        const ocrText = blocks.map((x) => `[p${x.p} b${x.b}] ${x.text}`).join("\n");

        const system = `
        You convert OCR from cookbook recipe pages into a strict JSON object for a recipe app.

        Rules:
        - Output MUST conform to the provided JSON schema (no extra keys).
        - Prefer correctness over guessing.
        - If a field is unknown, use null (or [] for arrays if you found none).
        - Ingredients: keep 'raw' exactly as seen (cleaned), and only fill quantity/unit/item/notes when confident.
        - Steps: keep as an ordered list of instructions (no numbering needed).
        - Title should be short and clean.
        - Add warnings (array of strings) for anything suspicious (e.g. missing steps, merged columns, OCR noise).
        - confidence: 0.0 to 1.0 (overall).
        `.trim();

        const userPrompt = `
        OCR blocks (in reading order, may include noise / headers / page numbers):

        ${ocrText}

        Extract the recipe.`.trim();

        // Use Pro for robustness (best extraction), Flash if you want cheaper later
        const model = "gemini-2.5-pro";

        const resp = await ai.models.generateContent({
            model,
            contents: userPrompt,
            config: {
                systemInstruction: system,
                temperature: 0,
                topP: 0,
                candidateCount: 1,
                responseMimeType: "application/json",
                responseSchema,
            },
        });

        // With responseMimeType JSON, resp.text should be JSON
        const parsed = safeJsonParse(resp.text);
        if (!parsed) {
            throw new HttpsError(
                "internal",
                "Model did not return valid JSON. Try again or log resp.text."
            );
        }

        // Minimal server-side cleanup to match your Ingredient.fromMap expectations
        if (Array.isArray(parsed.ingredients)) {
            parsed.ingredients = parsed.ingredients
                .map((ing) => ({
                    raw: asString(ing?.raw).trim(),
                    quantity:
                        typeof ing?.quantity === "number" && Number.isFinite(ing.quantity)
                            ? ing.quantity
                            : null,
                    unit: ing?.unit != null ? asString(ing.unit).trim() : null,
                    item: ing?.item != null ? asString(ing.item).trim() : null,
                    notes: ing?.notes != null ? asString(ing.notes).trim() : null,
                }))
                .filter((ing) => ing.raw.length > 0);
        }

        if (Array.isArray(parsed.steps)) {
            parsed.steps = parsed.steps.map((s) => asString(s).trim()).filter(Boolean);
        }

        if (Array.isArray(parsed.tags)) {
            parsed.tags = parsed.tags.map((t) => asString(t).trim()).filter(Boolean);
        }

        return parsed; // this becomes res.data in Flutter
    }
);

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { GoogleGenAI, Type } = require("@google/genai");
const axios = require("axios");
const cheerio = require("cheerio");

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

async function callGeminiParser(content) {
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
            pageNumber: { type: Type.INTEGER, nullable: true },
            sourceAuthor: { type: Type.STRING, nullable: true },
            sourceTitle: { type: Type.STRING, nullable: true },
        },
        required: ["title"],
    };

    const system = `
        You convert text from cooking recipes into a strict JSON object for a recipe app.

        Rules:
        - Output MUST conform to the provided JSON schema (no extra keys).
        - Prefer correctness over guessing.
        - If a field is unknown, use null (or [] for arrays if you found none).
        - Ingredients: keep 'raw' exactly as seen (cleaned), and only fill quantity/unit/item/notes when confident.
        - Steps: keep as an ordered list of instructions (no numbering needed).
        - Title should be short and clean.
        - Suggest a few short tags for the recipe using your knowledge.
        - If an ingredient is singular, for example 'a teaspoon', use 1 as the quantity.
        - Every field will be user facing - do not include technical jargon, ensure capitalisation is neat and grammatically correct.
        - Add the author of the recipe or chef to sourceAuthor, and the platform (eg tiktok/instagram) or website name (eg BBC Good Food) to sourceTitle.
        `.trim();

    const model = "gemini-2.5-pro";

    const resp = await ai.models.generateContent({
        model,
        contents: content,
        config: {
            systemInstruction: system,
            temperature: 0,
            topP: 0,
            candidateCount: 1,
            responseMimeType: "application/json",
            responseSchema,
        },
    });

    return resp;
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

        const ocrText = blocks.map((x) => `[p${x.p} b${x.b}] ${x.text}`).join("\n");
        const userPrompt = `
        OCR blocks (in reading order, may include noise / headers / page numbers):

        ${ocrText}

        Extract the recipe.`.trim();

        const resp = await callGeminiParser(userPrompt);

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


async function extractFromBlog(url) {
    try {
        // 1. Fetch the HTML with a standard User-Agent to avoid being blocked
        const response = await axios.get(url, {
            headers: {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
            },
            timeout: 10000, // 10s timeout for safety
        });

        const $ = cheerio.load(response.data);
        let structuredRecipe = null;

        // 2. Attempt to find JSON-LD (Schema.org Recipe data)
        $('script[type="application/ld+json"]').each((_, el) => {
            const json = safeJsonParse($(el).html());
            if (!json) return;

            // JSON-LD can be a single object, an array, or a "@graph"
            const potentialItems = Array.isArray(json) ? json : (json["@graph"] || [json]);

            const found = potentialItems.find(item =>
                item["@type"] === "Recipe" ||
                (Array.isArray(item["@type"]) && item["@type"].includes("Recipe"))
            );

            if (found) {
                structuredRecipe = found;
                return false; // Break loop
            }
        });

        let inputForGemini = "";

        if (structuredRecipe) {
            // Option A: We found clean data. Feed it to Gemini to "normalize" to your schema.
            inputForGemini = `
                EXTRACTED STRUCTURED DATA:
                ${JSON.stringify(structuredRecipe)}
                
                URL: ${url}
            `;
        } else {
            // Option B: No schema found. Extract title and body text as fallback.
            const title = $("title").text() || $("h1").first().text();
            // Remove scripts, styles, and nav to reduce noise for the AI
            $("script, style, nav, footer, header, noscript").remove();
            const bodyText = $("body").text().replace(/\s+/g, ' ').trim().substring(0, 15000);

            inputForGemini = `
                RAW WEBSITE CONTENT (No structured data found):
                Title: ${title}
                Content: ${bodyText}
                
                URL: ${url}
            `;
        }

        // 3. Call your updated Gemini function
        const geminiResponse = await callGeminiParser(inputForGemini);

        // Extract the actual JSON from the Gemini response object
        const parsed = safeJsonParse(geminiResponse.text);

        if (!parsed) {
            throw new Error("Gemini failed to return valid JSON for this URL.");
        }

        return parsed;

    } catch (err) {
        logger.error(`Blog extraction failed for ${url}`, err);
        throw new HttpsError("internal", `Could not extract recipe: ${err.message}`);
    }
}

async function extractFromInstagramReels(url) {
    try {
        console.log("Extracting recipe from instagram reels");
        // 1. set up api input json
        const token = process.env.APIFY_API_KEY;
        if (!token) throw new Error("Missing APIFY_API_KEY");
        const api_input = {
            "includeDownloadedVideo": false,
            "includeSharesCount": false,
            "includeTranscript": true,
            "resultsLimit": 1,
            "skipPinnedPosts": false,
            "username": [
                url
            ]
        }

        // 2. call api and wait for response (get api key from .env 'APIFY_API_KEY')
        const endpoint = `https://api.apify.com/v2/acts/apify~instagram-reel-scraper/run-sync-get-dataset-items?token=${token}`;
        console.log(`Calling APIFT endpoint`);
        const response = await axios.post(endpoint, api_input, {
            headers: { "Content-Type": "application/json" },
            timeout: 120000,
        });
        console.log("typeof response.data:", typeof response.data);
        console.log("isArray response.data:", Array.isArray(response.data));
        const items = response.data;
        console.log(`Got response from api`);
        if (!Array.isArray(items)) {
            throw new Error("Apify returned not an array.");
        }
        if (items.length === 0) {
            throw new Error("Apify returned an empty array.");
        }

        const reel = items[0];

        // 3) Build LLM input from caption/transcript/author
        const caption = (reel.caption ?? "").toString().trim();
        const transcript = (reel.transcript ?? "").toString().trim();
        const author =
            (reel.ownerFullName ?? reel.ownerUsername ?? "").toString().trim();

        const inputForGemini = `
            SOURCE: Instagram Reel. If some ingredients or some steps are missing or incomplete, please fill in the gaps yourself, but put a note in the note section saying which parts you filled in. If there is no ingredients and no steps, then please return blank fields.
            URL: ${url}
            RECIPE AUTHOR / CHEF: ${author || "Unknown"}

            CAPTION:
            ${caption || "(none)"}

            TRANSCRIPT:
            ${transcript || "(none)"}
            `.trim();
        console.log(`Calling gemini to fix recipe with input ${inputForGemini}`);

        // 4. Call Gemini function
        const geminiResponse = await callGeminiParser(inputForGemini);

        // Extract the actual JSON from the Gemini response object
        const parsed = safeJsonParse(geminiResponse.text);

        if (!parsed) {
            throw new Error("Gemini failed to return valid JSON for this URL.");
        }

        return parsed;
    } catch (err) {
        logger.error(`Reel extraction failed for ${url}`, err);
        throw new HttpsError("internal", `Could not extract recipe: ${err.message}`);
    }
}


async function extractFromTikTok(url) {
    try {
        console.log("Extracting recipe from tiktok");
        // 1. set up api input json
        const token = process.env.APIFY_API_KEY;
        if (!token) throw new Error("Missing APIFY_API_KEY");
        const api_input = {
            "resultsPerPage": 1,
            "scrapeRelatedVideos": false,
            "shouldDownloadCovers": false,
            "shouldDownloadSlideshowImages": false,
            "shouldDownloadSubtitles": false,
            "shouldDownloadVideos": false,
            "postURLs": [
                url
            ]
        }
        const transcribe_api_input = {
            "start_urls": url
        };

        // 2. call api and wait for response (get api key from .env 'APIFY_API_KEY')
        const endpoint = `https://api.apify.com/v2/acts/clockworks~tiktok-video-scraper/run-sync-get-dataset-items?token=${token}`;
        const transcribe_endpoint = `https://api.apify.com/v2/acts/tictechid~anoxvanzi-transcriber/run-sync-get-dataset-items?token=${token}`;
        console.log(`Calling APIFT endpoints`);
        const [response, transcribe_response] = await Promise.all([
            axios.post(endpoint, api_input, {
                headers: { "Content-Type": "application/json" },
                timeout: 120000,
            }),
            axios.post(transcribe_endpoint, transcribe_api_input, {
                headers: { "Content-Type": "application/json" },
                timeout: 120000,
            }),
        ]);
        const items = response.data;
        const transcribe_items = transcribe_response.data;
        console.log(`Got response from api`);
        if (!Array.isArray(items)) {
            throw new Error("Apify returned not an array.");
        }
        if (items.length === 0) {
            throw new Error("Apify returned an empty array.");
        }
        if (!Array.isArray(transcribe_items)) {
            throw new Error("Apify returned not an transcribe_items.");
        }
        if (transcribe_items.length === 0) {
            throw new Error("Apify returned an empty transcribe_items.");
        }

        const reel = items[0];

        // 3) Build LLM input from caption/transcript/author
        const caption = (reel.text ?? "").toString().trim();
        const transcript = (transcribe_items[0].transcript ?? "").toString().trim();
        const author =
            (reel.authorMeta.nickName ?? reel.authorMeta.name ?? "").toString().trim();

        const inputForGemini = `
            SOURCE: Tiktok. If some ingredients or some steps are missing or incomplete, please fill in the gaps yourself, but put a note in the note section saying which parts you filled in. If there is no ingredients and no steps, then please return blank fields.
            URL: ${url}
            RECIPE AUTHOR / CHEF:: ${author || "Unknown"}

            CAPTION:
            ${caption || "(none)"}

            TRANSCRIPT:
            ${transcript || "(none)"}
            `.trim();
        console.log(`Calling gemini to fix recipe with input ${inputForGemini}`);

        // 4. Call Gemini function
        const geminiResponse = await callGeminiParser(inputForGemini);

        // Extract the actual JSON from the Gemini response object
        const parsed = safeJsonParse(geminiResponse.text);

        if (!parsed) {
            throw new Error("Gemini failed to return valid JSON for this URL.");
        }

        return parsed;
    } catch (err) {
        logger.error(`Reel extraction failed for ${url}`, err);
        throw new HttpsError("internal", `Could not extract recipe: ${err.message}`);
    }
}


async function extractFromYouTube(url) {
    try {
        console.log("Extracting recipe from youtube");
        // 1. set up api input json
        const token = process.env.APIFY_API_KEY;
        if (!token) throw new Error("Missing APIFY_API_KEY");
        const details_api_input = {
            "include_transcript_text": false,
            "language": "en",
            "max_videos": 1,
            "youtube_url": url
        };
        const comments_api_input = {
            "commentsSortBy": "0",
            "maxComments": 3,
            "startUrls": [
                {
                    "url": url
                }
            ]
        }
        const transcribe_api_input = {
            "targetLanguage": "en",
            "videoUrl": url
        };

        // 2. call api and wait for response (get api key from .env 'APIFY_API_KEY')
        const details_endpoint = `https://api.apify.com/v2/acts/starvibe~youtube-video-transcript/run-sync-get-dataset-items?token=${token}`;
        const comments_endpoint = `https://api.apify.com/v2/acts/streamers~youtube-comments-scraper/run-sync-get-dataset-items?token=${token}`;
        const transcribe_endpoint = `https://api.apify.com/v2/acts/pintostudio~youtube-transcript-scraper/run-sync-get-dataset-items?token=${token}`;
        console.log(`Calling APIFT endpoints`);
        const [details_response, comments_response, transcribe_response] = await Promise.all([
            axios.post(details_endpoint, details_api_input, {
                headers: { "Content-Type": "application/json" },
                timeout: 120000,
            }),
            axios.post(comments_endpoint, comments_api_input, {
                headers: { "Content-Type": "application/json" },
                timeout: 120000,
            }),
            axios.post(transcribe_endpoint, transcribe_api_input, {
                headers: { "Content-Type": "application/json" },
                timeout: 120000,
            }),
        ]);
        const details_items = details_response.data;
        const comments_items = comments_response.data;
        const transcribe_items = transcribe_response.data;
        console.log(`Got response from api`);
        if (!Array.isArray(details_items)) {
            throw new Error("Apify returned not an array.");
        }
        if (details_items.length === 0) {
            throw new Error("Apify returned an empty array.");
        }
        if (!Array.isArray(comments_items)) {
            throw new Error("Apify returned not an comments array.");
        }
        if (comments_items.length === 0) {
            throw new Error("Apify returned an empty comments array.");
        }
        if (!Array.isArray(transcribe_items)) {
            throw new Error("Apify returned not an transcribe_items.");
        }
        if (transcribe_items.length === 0) {
            throw new Error("Apify returned an empty transcribe_items.");
        }

        // 3) Build LLM input from caption/transcript/author
        const details = details_items[0];
        const caption = (details.description ?? "").toString().trim();
        const title = (details.title ?? "").toString().trim();
        const author = (details.channel_name ?? "").toString().trim();

        const ownerReply =
            comments_items.find(c => c?.authorIsChannelOwner == true)?.comment ?? "";
        const authorComment = ownerReply.toString().trim();

        const transcript = (transcribe_items[0].data ?? "").toString().trim();

        const inputForGemini = `
            SOURCE: YouTube. If some ingredients or some steps are missing or incomplete, please fill in the gaps yourself, but put a note in the note section saying which parts you filled in. If there is no ingredients and no steps, then please return blank fields.
            URL: ${url}
            RECIPE AUTHOR / CHEF:: ${author || "Unknown"}

            TITLE:
            ${title || "(none)"}

            CAPTION:
            ${caption || "(none)"}

            PINNED COMMENT:
            ${authorComment || "(none)"}

            TRANSCRIPT:
            ${transcript || "(none)"}
            `.trim();
        console.log(`Calling gemini to fix recipe with input ${inputForGemini}`);

        // 4. Call Gemini function
        const geminiResponse = await callGeminiParser(inputForGemini);

        // Extract the actual JSON from the Gemini response object
        const parsed = safeJsonParse(geminiResponse.text);

        if (!parsed) {
            throw new Error("Gemini failed to return valid JSON for this URL.");
        }

        return parsed;
    } catch (err) {
        logger.error(`YouTube extraction failed for ${url}`, err);
        throw new HttpsError("internal", `Could not extract recipe: ${err.message}`);
    }
}

exports.recipeFromUrl = onCall({
    region: LOCATION,
    timeoutSeconds: 120, // Web scraping can take longer
    memory: "1GiB"
}, async (request) => {
    const urlString = (request.data?.url ?? "").toString().trim();
    console.log("Extracting recipe from url");
    if (!urlString) throw new HttpsError("invalid-argument", "Missing URL");

    try {
        const url = new URL(urlString);
        const domain = url.hostname.replace('www.', '');
        console.log(`Extracting recipe from domain ${domain}`);

        // 1. Route based on domain
        if (domain.includes("instagram")) {
            console.log("From instagram");
            return await extractFromInstagramReels(urlString);
        } else if (domain.includes("tiktok")) {
            console.log("From tiktok");
            return await extractFromTikTok(urlString);
        } else if (domain.includes("youtube") || domain.includes("youtu.be")) {
            console.log("From youtube");
            return await extractFromYouTube(urlString);
        } else {
            console.log("From website");
            // Default: Traditional Blog/Website
            return await extractFromBlog(urlString);
        }
    } catch (err) {
        logger.error("Recipe extraction failed", err);
        throw new HttpsError("internal", err.message);
    }
});


exports.substituteIngredient = onCall(
    {
        region: LOCATION,
        timeoutSeconds: 15,
        memory: "256MiB",
    },
    async (request) => {
        const recipe = request.data?.recipe;
        const ingredient = request.data?.ingredient;

        if (!recipe || !ingredient) {
            throw new HttpsError(
                "invalid-argument",
                "recipe and ingredient are required"
            );
        }

        const responseSchema = {
            type: Type.ARRAY,
            items: {
                type: Type.OBJECT,
                properties: {
                    raw: { type: Type.STRING },
                    quantity: { type: Type.NUMBER, nullable: true },
                    unit: { type: Type.STRING, nullable: true },
                    item: { type: Type.STRING },
                    notes: { type: Type.STRING, nullable: true },
                },
                required: ["raw"],
            },
        };

        const model = "gemini-2.5-flash-lite";

        const system = `
            You are helping substitute ingredients in recipes.

            Rules:
            - Suggest up to a maximum of 4 (but can be less) realistic substitutes.
            - Prefer common household ingredients.
            - Adjust quantities if needed.
            - Include short notes if substitute requires a different method, will change recipe taste/texture/consistency, or anything important to note etc.
            - Do not include explanations outside the JSON.
            `;

        const prompt = `
            Recipe: ${recipe}
            Ingredient to substitute: ${ingredient}
            `;

        const resp = await ai.models.generateContent({
            model,
            contents: prompt,
            config: {
                systemInstruction: system,
                temperature: 0.1,
                topP: 0,
                candidateCount: 1,
                responseMimeType: "application/json",
                responseSchema,
            },
        });

        return JSON.parse(resp.text);
    }
);
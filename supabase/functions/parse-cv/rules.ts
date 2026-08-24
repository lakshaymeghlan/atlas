// CV text → structured profile, with no model call.
//
// Deterministic section/date/entry parsing. It handles the layouts CVs actually
// use most of the time — a header block, then EXPERIENCE / EDUCATION / SKILLS /
// LANGUAGES headings — plus LinkedIn's "Save to PDF" export, which puts the
// company above the role and its sidebar above the name.
//
// This is honest-but-brittle by nature: a CV is a free-form document, and no
// rule set covers every layout. So every entry carries a confidence the app
// already knows how to act on — anything under 0.6 gets flagged for review on
// the Confirm Profile screen. A field we could not read is null, never a guess.

export interface ParsedProfile {
  full_name: string | null;
  headline: string | null;
  location: string | null;
  experiences: {
    role: string;
    company: string;
    start_date: string | null;
    end_date: string | null;
    description: string | null;
    confidence: number;
  }[];
  education: {
    institution: string;
    degree: string | null;
    field: string | null;
    start_year: string | null;
    end_year: string | null;
    confidence: number;
  }[];
  skills: { name: string; confidence: number }[];
  languages: { name: string; level: string | null }[];
}

// ---------------------------------------------------------------- confidence
//
// Rules-based parsing is never certain, so nothing here reaches 1.0. The bands
// are chosen against the app's 0.6 review threshold: CLEAN sits above it,
// PARTIAL and WEAK below, so the entries we're least sure of are exactly the
// ones the user is asked to check.
const CLEAN = 0.7; // structure and dates both read cleanly
const PARTIAL = 0.55; // one expected part missing
const WEAK = 0.4; // salvaged from an ambiguous line

// ------------------------------------------------------------------ sections

type Section = "experience" | "education" | "skills" | "languages" | "summary" | "contact";

const HEADINGS: [Section, RegExp][] = [
  ["experience", /^(work|professional|employment|relevant)?\s*(experience|history)$|^career\b|^employment$/i],
  ["education", /^(education|academic\b.*|qualifications|training)$/i],
  ["skills", /^(top\s+)?(skills?|technical skills?|technologies|expertise|core competencies|competencies)$/i],
  ["languages", /^languages?$/i],
  ["summary", /^(summary|profile|about|objective|professional summary)$/i],
  ["contact", /^(contact|contact info(rmation)?|details)$/i],
];

/** A heading is a short standalone line that names a section. */
function headingOf(line: string): Section | null {
  const t = line.trim().replace(/[:•\-–—]+$/, "").trim();
  if (!t || t.length > 40 || /[.!?]$/.test(t)) return null;
  for (const [section, re] of HEADINGS) if (re.test(t)) return section;
  return null;
}

// ---------------------------------------------------------------------- dates

const MONTH = "(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*";
const POINT = `(?:${MONTH}\\.?\\s*,?\\s*\\d{4}|\\d{1,2}/\\d{4}|\\d{4}-\\d{2}|\\d{4})`;
const NOW = "(?:present|current|now|ongoing|date)";
const RANGE = new RegExp(`(${POINT})\\s*(?:-|–|—|to|until)\\s*(${POINT}|${NOW})`, "i");
const YEAR = /\b(19|20)\d{2}\b/;

/** `start`/`end` as written in the document; `end` is null for a current role. */
function dateRange(text: string): { start: string | null; end: string | null } | null {
  const m = text.match(RANGE);
  if (!m) return null;
  const end = new RegExp(`^${NOW}$`, "i").test(m[2].trim()) ? null : m[2].trim();
  return { start: m[1].trim(), end };
}

/** Strip a date range and any duration LinkedIn appends ("(2 years 3 months)"). */
function withoutDates(line: string): string {
  return line
    .replace(RANGE, " ")
    .replace(/\(\s*\d+\s*(year|yr|month|mo)s?[^)]*\)/gi, " ")
    .replace(/[（(]\s*[)）]/g, " ") // "(2014 - 2018)" leaves "( )" behind
    .replace(/\s{2,}/g, " ")
    .replace(/^[\s,·|•\-–—]+|[\s,·|•\-–—]+$/g, "")
    .trim();
}

// -------------------------------------------------------------------- tidying

const NOISE = [
  /^page\s+\d+\s+of\s+\d+$/i,
  /^\d+\s*\/\s*\d+$/,
  /^[-–—_=•·.\s]+$/,
  /^curriculum vitae$|^résumé$|^resume$/i,
];
const CONTACT = /@|https?:\/\/|www\.|linkedin\.com|github\.com|^\+?[\d\s()\-.]{7,}$/i;

function lines(text: string): string[] {
  return text
    .replace(/\r/g, "\n")
    .split("\n")
    .map((l) => l.replace(/[\t ]+/g, " ").trim())
    .filter((l) => l && !NOISE.some((re) => re.test(l)));
}

/** Trim list/sentence punctuation from the edges of an extracted value. */
function tidy(v: string): string {
  return v.replace(/^[\s,.·|•\-–—]+/, "").replace(/[\s,·|•\-–—]+$/, "").replace(/\.$/, "").trim();
}

/** Split a "Role at Company" / "Role, Company" / "Role — Company" line. */
function splitPair(line: string): [string, string] | null {
  const at = line.match(/^(.{2,80}?)\s+(?:at|@|with)\s+(.{2,80})$/i);
  if (at) return [at[1].trim(), at[2].trim()];
  const sep = line.match(/^(.{2,80}?)\s*(?:,|\||·|–|—| - )\s*(.{2,80})$/);
  if (sep) return [sep[1].trim(), sep[2].trim()];
  return null;
}

// ------------------------------------------------------------------- LinkedIn

/**
 * LinkedIn's PDF export is distinctive and inverted: the sidebar (Contact / Top
 * Skills / Languages) extracts *before* the name, and each role lists the
 * company above the title. Detecting it is worth the branch — parsed as a
 * generic CV, every role comes out with role and company swapped.
 */
function isLinkedInExport(text: string): boolean {
  const head = text.slice(0, 2000).toLowerCase();
  return /linkedin\.com\/in\//.test(head) ||
    (/\btop skills\b/.test(head) && /\bcontact\b/.test(head));
}

// --------------------------------------------------------------------- header

const DEGREE =
  /\b(b\.?[as]c?\.?|m\.?[as]c?\.?|ph\.?d|mba|bachelor'?s?|master'?s?|doctorate|diploma|certificate|hnd|foundation)\b/i;
const SCHOOL =
  /\b(university|universität|college|school|institute|academy|polytechnic|hochschule|escuela|universidad)\b/i;

function looksLikeName(line: string): boolean {
  if (CONTACT.test(line) || /[\d()]/.test(line)) return false; // "English (Native)" is not a name
  if (headingOf(line) || DEGREE.test(line) || SCHOOL.test(line)) return false;
  // A person's name carries no list punctuation ("Berlin, Germany") and no role
  // word ("Senior Product Designer") — both otherwise look exactly like names.
  if (/[,|·\/]/.test(line) || JOB_WORD.test(line)) return false;
  const words = line.split(/\s+/);
  if (words.length < 2 || words.length > 5) return false;
  // Every word starts uppercase (allows "van", "de", "bin" particles).
  return words.every((w) => /^[A-Z]/.test(w) || /^(van|von|de|del|da|di|bin|al|la|le)$/i.test(w));
}

const LOCATION =
  /^[A-Z][\w.'-]+(?:[\s-][A-Z][\w.'-]+)*,\s*[A-Z][\w.'-]+(?:[\s-][A-Z][\w.'-]+)*(?:,\s*[A-Z]{2,})?$/;

/**
 * Job titles are shaped exactly like places — "Product Designer, Riverbank"
 * has the same form as "Berlin, Germany" — so the pattern alone is not enough.
 * A role word rules a line out, and a place name or region code rules it in.
 */
const JOB_WORD =
  /\b(engineer|developer|designer|manager|director|lead|analyst|consultant|intern|head|officer|architect|scientist|specialist|president|founder|partner|associate|assistant|coordinator|administrator|technician|editor|writer|researcher|professor|teacher|accountant|advisor|strategist|recruiter|owner|ceo|cto|cfo|coo|vp)\b/i;

// ponytail: a short list, not ISO 3166 — covers the app's EU/US market and the
// forms LinkedIn emits. Extend it when a real CV parses its location wrong.
const COUNTRY =
  /\b(germany|deutschland|france|spain|españa|italy|italia|netherlands|belgium|portugal|poland|sweden|norway|denmark|finland|ireland|switzerland|austria|czechia|czech republic|greece|romania|hungary|bulgaria|croatia|slovakia|slovenia|estonia|latvia|lithuania|luxembourg|iceland|united kingdom|uk|england|scotland|wales|united states|usa|canada|mexico|brazil|argentina|chile|colombia|india|pakistan|china|japan|korea|singapore|malaysia|indonesia|thailand|vietnam|philippines|australia|new zealand|uae|united arab emirates|saudi arabia|qatar|israel|turkey|egypt|morocco|nigeria|kenya|ghana|south africa)\b/i;

function looksLikeLocation(line: string): boolean {
  if (line.length > 45 || CONTACT.test(line) || SCHOOL.test(line)) return false;
  if (JOB_WORD.test(line)) return false;
  if (/^(remote|hybrid|on-?site)\b/i.test(line)) return true;
  if (/\bgreater\b[\s\S]*\barea\b/i.test(line)) return true;
  if (!LOCATION.test(line)) return false;
  // Needs a place signal, or "Go, Rust" reads as a city in a country.
  return COUNTRY.test(line) || /,\s*[A-Z]{2}$/.test(line);
}

// ---------------------------------------------------------------------- parse

/** Group the document's lines by the section heading they fall under. */
function sectionize(all: string[]): { header: string[]; sections: Map<Section, string[]> } {
  const header: string[] = [];
  const sections = new Map<Section, string[]>();
  let current: Section | null = null;

  for (const line of all) {
    const heading = headingOf(line);
    if (heading) {
      current = heading;
      if (!sections.has(heading)) sections.set(heading, []);
      continue;
    }
    if (current) sections.get(current)!.push(line);
    else header.push(line);
  }
  return { header, sections };
}

/** A short, non-prose line — the shape of a role, company, or school name. */
function titleish(line: string): boolean {
  return line.length <= 60 && line.split(/\s+/).length <= 8 &&
    !/[.!?]$/.test(line) && !looksLikeLocation(line) && !CONTACT.test(line);
}

/**
 * Split a section body into entries.
 *
 * An entry accumulates until it has a date range *and* we hit the next
 * title-like line (or another date) — that pairing is what marks the previous
 * entry complete. Keying off dates alone would split every role from its own
 * date line; keying off title lines alone would split every description.
 */
function entries(body: string[]): string[][] {
  const out: string[][] = [];
  let cur: string[] = [];

  for (const line of body) {
    const dated = cur.some((l) => RANGE.test(l));
    const boundary = cur.length > 0 && dated && (RANGE.test(line) || titleish(line));
    if (boundary) {
      out.push(cur);
      cur = [line];
    } else {
      cur.push(line);
    }
  }
  if (cur.length) out.push(cur);
  return out.filter((e) => e.length);
}

function parseExperience(body: string[], linkedIn: boolean): ParsedProfile["experiences"] {
  const out: ParsedProfile["experiences"] = [];

  for (const entry of entries(body)) {
    const dated = entry.find((l) => RANGE.test(l));
    const range = dated ? dateRange(dated) : null;

    // Candidate title lines: the entry's non-date lines, in order.
    const titles = entry
      .map((l) => (l === dated ? withoutDates(l) : l))
      .filter((l) => l && !CONTACT.test(l) && !looksLikeLocation(l));

    let role = "", company = "", used = 0;
    const pair = titles[0] ? splitPair(titles[0]) : null;
    if (pair) {
      // "Role at Company" on one line — LinkedIn never does this, so no swap.
      [role, company] = pair;
      used = 1;
    } else if (titles.length >= 2) {
      // Two stacked lines. LinkedIn puts the company first; CVs put the role first.
      [role, company] = linkedIn ? [titles[1], titles[0]] : [titles[0], titles[1]];
      used = 2;
    } else if (titles.length === 1) {
      role = titles[0];
      used = 1;
    }

    role = tidy(role);
    company = tidy(company);
    if (!role && !company) continue;

    const description = titles.slice(used).join(" ").trim() || null;
    const confidence = role && company && range ? CLEAN : role && company ? PARTIAL : WEAK;

    out.push({
      role: role || company,
      company: role ? company : "",
      start_date: range?.start ?? null,
      end_date: range?.end ?? null,
      description,
      confidence,
    });
  }
  return out;
}

/** The comma-separated part naming the school, for entries packed onto one line. */
function schoolPart(line: string): string | null {
  if (!SCHOOL.test(line)) return null;
  const clean = withoutDates(line);
  return tidy(clean.split(/\s*,\s*/).find((p) => SCHOOL.test(p)) ?? clean);
}

function parseEducation(body: string[]): ParsedProfile["education"] {
  const out: ParsedProfile["education"] = [];

  for (const entry of entries(body)) {
    const joined = entry.join(" ");
    const range = dateRange(joined);
    // A lone year is common in education blocks; treat it as the end year.
    const lone = !range ? joined.match(YEAR) : null;

    const institution = entry.map(schoolPart).find(Boolean) ??
      tidy(entry.find((l) => !DEGREE.test(l) && !RANGE.test(l) && l.length > 2) ?? entry[0] ?? "");
    if (!institution) continue;

    const degreeLine = entry.find((l) => DEGREE.test(l)) ?? "";
    const degree = degreeLine.match(DEGREE)?.[0]?.replace(/[.,]$/, "") ?? null;

    // Field: what remains of the degree line once the degree word, the dates and
    // the institution are removed — so a one-line entry doesn't repeat itself.
    let field: string | null = null;
    if (degreeLine) {
      const rest = tidy(
        withoutDates(degreeLine)
          .replace(DEGREE, " ")
          .replace(institution, " ")
          .replace(/\b(in|of)\b/gi, " ")
          .replace(/\s{2,}/g, " "),
      );
      if (rest.length > 1 && rest.toLowerCase() !== institution.toLowerCase()) field = rest;
    }

    out.push({
      institution,
      degree,
      field,
      start_year: range?.start?.match(YEAR)?.[0] ?? null,
      end_year: range?.end?.match(YEAR)?.[0] ?? lone?.[0] ?? null,
      confidence: degree || range ? CLEAN : PARTIAL,
    });
  }
  return out;
}

function parseSkills(body: string[]): ParsedProfile["skills"] {
  const seen = new Set<string>();
  const out: ParsedProfile["skills"] = [];

  for (const raw of body.flatMap((l) => l.split(/[,;•·|\/]|\s{3,}/))) {
    const name = raw.replace(/^[\s\-–—*]+|[\s.]+$/g, "").trim();
    // Skip prose: a skill is a short noun phrase, not a sentence.
    if (name.length < 2 || name.length > 40 || name.split(/\s+/).length > 4) continue;
    if (CONTACT.test(name) || headingOf(name)) continue;
    const key = name.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    // A listed skill is a fact; how well it's *split* is the uncertainty.
    out.push({ name, confidence: CLEAN });
  }
  return out;
}

const LEVEL =
  /\b(native|bilingual|fluent|professional|conversational|intermediate|basic|beginner|elementary|advanced|proficient|mother tongue|[ABC][12])\b/i;

function parseLanguages(body: string[]): ParsedProfile["languages"] {
  const out: ParsedProfile["languages"] = [];
  const seen = new Set<string>();

  for (const raw of body.flatMap((l) => l.split(/[,;•|]/))) {
    const line = raw.trim();
    if (!line || line.length > 60) continue;
    // "English (Native)" / "English — Fluent" / "English"
    const paren = line.match(/^(.{2,30}?)\s*[（(]\s*([^)）]+)\s*[)）]$/);
    const dash = line.match(/^(.{2,30}?)\s*(?:[-–—:]|\s{2,})\s*(.{2,30})$/);
    let name = line, level: string | null = null;
    if (paren) { name = paren[1].trim(); level = paren[2].trim(); }
    else if (dash && LEVEL.test(dash[2])) { name = dash[1].trim(); level = dash[2].trim(); }
    else if (LEVEL.test(line)) {
      const m = line.match(LEVEL)!;
      name = line.slice(0, m.index).trim() || line;
      level = m[0];
    }
    name = name.replace(/[\s.:-]+$/, "").trim();
    if (name.length < 2 || name.split(/\s+/).length > 3) continue;
    const key = name.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push({ name, level });
  }
  return out;
}

/** Parse extracted CV text into the app's `CVParseResult` shape. */
export function parseCV(text: string): ParsedProfile {
  const linkedIn = isLinkedInExport(text);
  const all = lines(text);

  // LinkedIn's sidebar (Contact / Top Skills / Languages) linearises *ahead* of
  // the identity block, so the name is the last name-shaped line before the
  // Summary/Experience heading — not the first one in the document. Those lines
  // also belong to no section, and would otherwise be read as more sidebar
  // entries (a name parsed as a language).
  let identity: string[] = [];
  let rest = all;
  if (linkedIn) {
    const bodyStart = all.findIndex((l) => {
      const h = headingOf(l);
      return h === "summary" || h === "experience";
    });
    if (bodyStart > 0) {
      let nameAt = -1;
      for (let i = bodyStart - 1; i >= 0; i--) {
        if (looksLikeName(all[i])) { nameAt = i; break; }
      }
      if (nameAt >= 0) {
        identity = all.slice(nameAt, bodyStart);
        rest = [...all.slice(0, nameAt), ...all.slice(bodyStart)];
      }
    }
  }

  const { header, sections } = sectionize(rest);
  const nameSource = identity.length ? identity : header.length ? header : rest;
  const full_name = nameSource.find(looksLikeName) ?? null;

  const afterName = full_name ? nameSource.slice(nameSource.indexOf(full_name) + 1) : nameSource;
  const location = afterName.find(looksLikeLocation) ??
    rest.slice(0, 15).find(looksLikeLocation) ?? null;

  // Headline: the first substantive line after the name that isn't the location
  // or contact noise. Falls back to the first line of a Summary section.
  const headline =
    afterName.find(
      (l) =>
        l !== location && !CONTACT.test(l) && !looksLikeLocation(l) &&
        l.length > 3 && l.length <= 120 && !headingOf(l),
    ) ??
    sections.get("summary")?.[0]?.slice(0, 120) ??
    null;

  return {
    full_name,
    headline,
    location,
    experiences: parseExperience(sections.get("experience") ?? [], linkedIn),
    education: parseEducation(sections.get("education") ?? []),
    skills: parseSkills(sections.get("skills") ?? []),
    languages: parseLanguages(sections.get("languages") ?? []),
  };
}

/** True when the parse found enough to be worth showing the user. */
export function isUsable(p: ParsedProfile): boolean {
  return Boolean(p.full_name) || p.experiences.length > 0 || p.education.length > 0 ||
    p.skills.length > 0;
}

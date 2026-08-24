// deno test --allow-none parse-cv/rules_test.ts
import { assert, assertEquals } from "jsr:@std/assert@1";
import { isUsable, parseCV } from "./rules.ts";

// A conventional CV: header block, uppercase headings, "Role, Company" lines.
const CONVENTIONAL = `Jordan Rivera
Berlin, Germany
Senior Product Designer
jordan@example.com | +49 30 1234567

EXPERIENCE

Senior Product Designer, Riverbank
2022 - Present
Led design for the onboarding and activation surfaces.

Product Designer, Northwind Labs
2019 - 2022
Shipped the mobile redesign and the design system.

EDUCATION

BA, Communication Design
University of the Arts
2014 - 2018

SKILLS
Figma, Design systems, Prototyping, SwiftUI, Accessibility

LANGUAGES
English (Native), German (Professional), Spanish
`;

// LinkedIn "Save to PDF": sidebar first, company above role, duration suffixes.
const LINKEDIN = `Contact
www.linkedin.com/in/jordanrivera
(LinkedIn)

Top Skills
Figma
Design Systems
Prototyping

Languages
English (Native or Bilingual)
German (Professional Working)

Jordan Rivera
Senior Product Designer
Berlin, Germany

Summary
Product designer focused on tools for people in transition.

Experience

Riverbank
Senior Product Designer
January 2022 - Present (2 years 4 months)
Berlin, Germany

Northwind Labs
Product Designer
June 2019 - December 2021 (2 years 7 months)

Education

University of the Arts
BA, Communication Design · (2014 - 2018)

Page 1 of 2
`;

Deno.test("conventional CV: header fields", () => {
  const p = parseCV(CONVENTIONAL);
  assertEquals(p.full_name, "Jordan Rivera");
  assertEquals(p.location, "Berlin, Germany");
  assertEquals(p.headline, "Senior Product Designer");
});

Deno.test("conventional CV: experience with role/company split and dates", () => {
  const p = parseCV(CONVENTIONAL);
  assertEquals(p.experiences.length, 2);
  assertEquals(p.experiences[0].role, "Senior Product Designer");
  assertEquals(p.experiences[0].company, "Riverbank");
  assertEquals(p.experiences[0].start_date, "2022");
  assertEquals(p.experiences[0].end_date, null, "Present must become null");
  assertEquals(p.experiences[1].company, "Northwind Labs");
  assertEquals(p.experiences[1].end_date, "2022");
});

Deno.test("conventional CV: education, skills, languages", () => {
  const p = parseCV(CONVENTIONAL);
  assertEquals(p.education.length, 1);
  assertEquals(p.education[0].institution, "University of the Arts");
  assertEquals(p.education[0].degree, "BA");
  assertEquals(p.education[0].start_year, "2014");
  assertEquals(p.education[0].end_year, "2018");

  assertEquals(p.skills.map((s) => s.name), [
    "Figma", "Design systems", "Prototyping", "SwiftUI", "Accessibility",
  ]);

  assertEquals(p.languages, [
    { name: "English", level: "Native" },
    { name: "German", level: "Professional" },
    { name: "Spanish", level: null },
  ]);
});

Deno.test("LinkedIn export: company-above-role is not swapped", () => {
  const p = parseCV(LINKEDIN);
  assertEquals(p.full_name, "Jordan Rivera");
  assertEquals(p.experiences.length, 2);
  // The whole point of LinkedIn detection: role and company the right way round.
  assertEquals(p.experiences[0].role, "Senior Product Designer");
  assertEquals(p.experiences[0].company, "Riverbank");
  assertEquals(p.experiences[1].role, "Product Designer");
  assertEquals(p.experiences[1].company, "Northwind Labs");
});

Deno.test("LinkedIn export: dates, duration suffix stripped, sidebar parsed", () => {
  const p = parseCV(LINKEDIN);
  assertEquals(p.experiences[0].start_date, "January 2022");
  assertEquals(p.experiences[0].end_date, null);
  assertEquals(p.experiences[1].end_date, "December 2021");
  // "(2 years 4 months)" must not survive into any field.
  assert(
    !JSON.stringify(p).includes("years"),
    "LinkedIn duration suffix leaked into the parse",
  );
  assertEquals(p.skills.map((s) => s.name), ["Figma", "Design Systems", "Prototyping"]);
  assertEquals(p.languages[0], { name: "English", level: "Native or Bilingual" });
  assertEquals(p.education[0].institution, "University of the Arts");
  assertEquals(p.education[0].degree, "BA");
  assertEquals(p.education[0].end_year, "2018");
});

Deno.test("page footers and separator noise are dropped", () => {
  const p = parseCV(LINKEDIN);
  assert(!JSON.stringify(p).includes("Page 1"), "page footer leaked into the parse");
});

Deno.test("confidence: complete entries clear the app's 0.6 review threshold", () => {
  const p = parseCV(CONVENTIONAL);
  for (const e of p.experiences) {
    assert(e.confidence > 0.6, `expected review-clear confidence, got ${e.confidence}`);
    assert(e.confidence <= 0.75, "rules parsing must never claim near-certainty");
  }
});

Deno.test("confidence: an entry missing its dates is flagged for review", () => {
  const p = parseCV(`Ana Vidal

EXPERIENCE
Engineer, Someplace

SKILLS
Go
`);
  assertEquals(p.experiences.length, 1);
  assert(
    p.experiences[0].confidence < 0.6,
    "a dateless entry should fall below the review threshold",
  );
});

Deno.test("never invents a value: absent fields are null", () => {
  const p = parseCV("Ana Vidal\n\nSKILLS\nGo, Rust\n");
  assertEquals(p.location, null);
  assertEquals(p.experiences, []);
  assertEquals(p.education, []);
  assertEquals(p.languages, []);
  assertEquals(p.skills.length, 2);
});

Deno.test("prose is not mistaken for skills", () => {
  const p = parseCV(`Ana Vidal

SKILLS
I am a highly motivated self-starter who thrives in ambiguous environments.
Go
`);
  assertEquals(p.skills.map((s) => s.name), ["Go"]);
});

Deno.test("garbage in: empty parse, reported as unusable", () => {
  const p = parseCV("....\n---\n\n   \n");
  assertEquals(isUsable(p), false);
  assertEquals(p.full_name, null);
  assertEquals(p.experiences, []);
});

Deno.test("a real parse is reported as usable", () => {
  assert(isUsable(parseCV(CONVENTIONAL)));
  assert(isUsable(parseCV(LINKEDIN)));
});

Deno.test("month/year and slash date formats", () => {
  const p = parseCV(`Ana Vidal

EXPERIENCE
Engineer, Alpha
Mar 2019 - Sept 2021

Engineer, Beta
03/2017 - 02/2019
`);
  assertEquals(p.experiences[0].start_date, "Mar 2019");
  assertEquals(p.experiences[0].end_date, "Sept 2021");
  assertEquals(p.experiences[1].start_date, "03/2017");
});

Deno.test("alternative heading vocabulary is recognised", () => {
  const p = parseCV(`Ana Vidal

WORK HISTORY
Engineer, Alpha
2019 - 2021

ACADEMIC BACKGROUND
MSc, Physics
Imperial College
2015 - 2019

TECHNICAL SKILLS
Rust, C++
`);
  assertEquals(p.experiences.length, 1);
  assertEquals(p.education.length, 1);
  assertEquals(p.education[0].degree, "MSc");
  assertEquals(p.skills.length, 2);
});

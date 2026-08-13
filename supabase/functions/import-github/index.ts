// Supabase Edge Function: import-github
//
// Pulls public GitHub data for a username into the app's GitHubData shape.
// Public REST — no auth needed. Set GITHUB_TOKEN to raise the rate limit AND
// enable the real contributions-last-year figure (via GraphQL); without a token
// that number comes back 0.
//
//   POST { username: "octocat" }
//   → 200 { username, name, avatarUrl, repoCount, followers,
//           contributionsLastYear, projects:[{name,description,language,stars,forks,pinned}] }
//   → 404 { error: "user not found" }
//
// Run:    supabase functions serve import-github --no-verify-jwt
// Deploy: supabase functions deploy import-github

const GITHUB_TOKEN = Deno.env.get("GITHUB_TOKEN") ?? "";
const MAX_PROJECTS = 12;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...CORS },
  });
}

function ghHeaders(): HeadersInit {
  const h: Record<string, string> = {
    "user-agent": "CanopyBot/1.0",
    "accept": "application/vnd.github+json",
  };
  if (GITHUB_TOKEN) h["authorization"] = `Bearer ${GITHUB_TOKEN}`;
  return h;
}

interface GhRepo {
  name: string;
  description: string | null;
  language: string | null;
  stargazers_count: number;
  forks_count: number;
  fork: boolean;
}

async function contributionsLastYear(login: string): Promise<number> {
  if (!GITHUB_TOKEN) return 0; // GraphQL requires a token
  const query = `query($login:String!){ user(login:$login){ contributionsCollection{ contributionCalendar{ totalContributions } } } }`;
  try {
    const res = await fetch("https://api.github.com/graphql", {
      method: "POST",
      headers: { ...ghHeaders(), "content-type": "application/json" },
      body: JSON.stringify({ query, variables: { login } }),
    });
    if (!res.ok) return 0;
    const data = await res.json();
    return data?.data?.user?.contributionsCollection?.contributionCalendar?.totalContributions ?? 0;
  } catch {
    return 0;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  let username = "";
  try {
    username = String((await req.json()).username ?? "").trim().replace(/^@/, "");
  } catch {
    return json({ error: "invalid JSON body" }, 400);
  }
  if (!username) return json({ error: "username required" }, 400);

  // Profile
  const userRes = await fetch(`https://api.github.com/users/${encodeURIComponent(username)}`, { headers: ghHeaders() });
  if (userRes.status === 404) return json({ error: "user not found" }, 404);
  if (!userRes.ok) return json({ error: `github ${userRes.status}` }, 502);
  const user = await userRes.json();

  // Repos (most recently pushed first, then we rank by stars for display)
  const reposRes = await fetch(
    `https://api.github.com/users/${encodeURIComponent(username)}/repos?per_page=100&sort=pushed`,
    { headers: ghHeaders() },
  );
  const repos: GhRepo[] = reposRes.ok ? await reposRes.json() : [];

  const projects = repos
    .filter((r) => !r.fork)
    .sort((a, b) => b.stargazers_count - a.stargazers_count)
    .slice(0, MAX_PROJECTS)
    .map((r, i) => ({
      name: r.name,
      description: r.description,
      language: r.language,
      stars: r.stargazers_count,
      forks: r.forks_count,
      pinned: i < 3, // default: top 3 by stars; the user can re-pin in the app
    }));

  return json({
    username: user.login,
    name: user.name ?? null,
    avatarUrl: user.avatar_url ?? null,
    repoCount: user.public_repos ?? projects.length,
    followers: user.followers ?? 0,
    contributionsLastYear: await contributionsLastYear(username),
    projects,
  });
});

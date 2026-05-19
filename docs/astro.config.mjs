// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

import tailwindcss from "@tailwindcss/vite";

import mdx from "@astrojs/mdx";

import cloudflare from "@astrojs/cloudflare";

// https://astro.build/config
export default defineConfig({
  base: "/",
  site: "https://usectrl.dev",

  integrations: [
    starlight({
      title: "Documentation \\\\ Control Center",
      // Match the marketing design system (see src/styles/global.css).
      customCss: ["./src/styles/starlight.css"],
      components: {
        // Brand mark + wordmark in the header, plus a ThemeSelect override
        // that renders the marketing site's shared system/light/dark chooser.
        SiteTitle: "./src/components/starlight/SiteTitle.astro",
        ThemeSelect: "./src/components/starlight/ThemeSelect.astro",
        // Append per-page JSON-LD (TechArticle + BreadcrumbList) on top of
        // Starlight's built-in head tags.
        Head: "./src/components/starlight/Head.astro",
      },
      titleDelimiter: " \\\\ ",
      // Self-host the same fonts as the marketing site; preload to avoid FOUT.
      // Theme is handled by Starlight's ThemeProvider (no-flash) + the
      // ThemeSelect override; dark tokens live in src/styles/starlight.css.
      head: [
        {
          tag: "link",
          attrs: {
            rel: "preload",
            href: "/fonts/Manrope-Variable.woff2",
            as: "font",
            type: "font/woff2",
            crossorigin: true,
          },
        },
        {
          tag: "link",
          attrs: {
            rel: "preload",
            href: "/fonts/FiraCode-VF.woff2",
            as: "font",
            type: "font/woff2",
            crossorigin: true,
          },
        },
      ],
      // Code blocks themed to our warm surfaces + Fira Code. Both a light
      // and dark theme are provided so Expressive Code syncs with data-theme;
      // the surface colors are pinned to our --cc-* tokens (which flip), so
      // only the syntax token colors differ between the two.
      expressiveCode: {
        themes: ["github-light", "github-dark"],
        styleOverrides: {
          borderRadius: "0.125rem",
          borderColor: "var(--cc-border)",
          codeBackground: "var(--cc-rail)",
          codeFontFamily:
            "'Fira Code', ui-monospace, 'SF Mono', Menlo, Consolas, monospace",
          codeFontSize: "0.8125rem",
          frames: {
            editorTabBarBackground: "var(--cc-surface)",
            editorActiveTabBackground: "var(--cc-panel)",
            editorActiveTabIndicatorBottomColor: "var(--cc-accent)",
            terminalBackground: "var(--cc-rail)",
            terminalTitlebarBackground: "var(--cc-surface)",
            frameBoxShadowCssValue: "none",
          },
        },
      },
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/SamuelAlev/control-center",
        },
      ],
      sidebar: [
        {
          label: "Getting started",
          items: [
            { label: "Introduction", slug: "manual" },
            { label: "Quick start", slug: "manual/quick-start" },
            { label: "Install", slug: "manual/install" },
          ],
        },
        {
          label: "Tutorials",
          items: [
            {
              label: "Your first workspace",
              slug: "manual/tutorials/first-workspace",
            },
            {
              label: "Dispatch your first agent",
              slug: "manual/tutorials/first-agent",
            },
            {
              label: "Review your first pull request",
              slug: "manual/tutorials/first-pr",
            },
            {
              label: "Build your first pipeline",
              slug: "manual/tutorials/first-pipeline",
            },
          ],
        },
        {
          label: "Concepts",
          items: [
            {
              label: "Workspaces and isolation",
              slug: "manual/concepts/workspaces",
            },
            { label: "The agent model", slug: "manual/concepts/agent-model" },
            {
              label: "Agent dispatch lifecycle",
              slug: "manual/concepts/dispatch-lifecycle",
            },
            {
              label: "Conversation modes",
              slug: "manual/concepts/conversation-modes",
            },
            {
              label: "Sandbox and security",
              slug: "manual/concepts/sandbox-security",
            },
            {
              label: "Memory and knowledge",
              slug: "manual/concepts/memory-knowledge",
            },
            {
              label: "Pipelines and automation",
              slug: "manual/concepts/pipelines",
            },
            {
              label: "Tickets and delegation",
              slug: "manual/concepts/tickets",
            },
            {
              label: "Orchestration",
              slug: "manual/concepts/orchestration",
            },
            {
              label: "Meetings and transcription",
              slug: "manual/concepts/meetings",
            },
            {
              label: "Calendar and scheduling",
              slug: "manual/concepts/calendar",
            },
            {
              label: "Remote control and mobile",
              slug: "manual/concepts/remote-control",
            },
            { label: "Domain events", slug: "manual/concepts/domain-events" },
            { label: "Architecture", slug: "manual/concepts/architecture" },
            {
              label: "Deployment and clients",
              slug: "manual/concepts/deployment",
            },
          ],
        },
        {
          label: "How-to guides",
          items: [
            {
              label: "Agents",
              items: [
                {
                  label: "Create and configure an agent",
                  slug: "manual/guides/create-agent",
                },
                {
                  label: "Run agents in parallel",
                  slug: "manual/guides/parallel-agents",
                },
                {
                  label: "Build an agent team",
                  slug: "manual/guides/build-team",
                },
                {
                  label: "Manage costs and budgets",
                  slug: "manual/guides/manage-costs",
                },
                {
                  label: "Run agent diagnostics",
                  slug: "manual/guides/agent-diagnostics",
                },
              ],
            },
            {
              label: "Workspaces",
              items: [
                {
                  label: "Add repos to a workspace",
                  slug: "manual/guides/add-repos",
                },
                {
                  label: "Manage workspace memory",
                  slug: "manual/guides/manage-memory",
                },
                {
                  label: "Search code with the code graph",
                  slug: "manual/guides/code-search",
                },
              ],
            },
            {
              label: "Pull requests",
              items: [
                {
                  label: "Review and merge a PR",
                  slug: "manual/guides/review-merge-pr",
                },
                {
                  label: "Use AI-powered review",
                  slug: "manual/guides/ai-review",
                },
                {
                  label: "Dispatch reviewer agents",
                  slug: "manual/guides/dispatch-reviewers",
                },
                { label: "Use focus mode", slug: "manual/guides/focus-mode" },
              ],
            },
            {
              label: "Messaging",
              items: [
                {
                  label: "Chat with an agent",
                  slug: "manual/guides/chat-with-agent",
                },
                {
                  label: "Use channels and DMs",
                  slug: "manual/guides/channels",
                },
                {
                  label: "@-mention agents",
                  slug: "manual/guides/mention-agents",
                },
                { label: "Use plan mode", slug: "manual/guides/plan-mode" },
              ],
            },
            {
              label: "Pipelines",
              items: [
                {
                  label: "Create a pipeline template",
                  slug: "manual/guides/create-pipeline",
                },
                {
                  label: "Run a pipeline manually",
                  slug: "manual/guides/run-pipeline",
                },
                {
                  label: "Set up pipeline triggers",
                  slug: "manual/guides/pipeline-triggers",
                },
                {
                  label: "Monitor pipeline runs",
                  slug: "manual/guides/monitor-pipelines",
                },
                {
                  label: "Run an orchestration",
                  slug: "manual/guides/run-orchestration",
                },
              ],
            },
            {
              label: "Ticketing",
              items: [
                {
                  label: "Create and manage tickets",
                  slug: "manual/guides/manage-tickets",
                },
                {
                  label: "Delegate work to agents",
                  slug: "manual/guides/delegate-tickets",
                },
                {
                  label: "Organize work with projects",
                  slug: "manual/guides/projects",
                },
              ],
            },
            {
              label: "Meetings & calendar",
              items: [
                {
                  label: "Record and summarize a meeting",
                  slug: "manual/guides/record-meeting",
                },
                {
                  label: "Connect a Google Calendar",
                  slug: "manual/guides/connect-calendar",
                },
              ],
            },
            {
              label: "Deployment",
              items: [
                {
                  label: "Run a headless server",
                  slug: "manual/guides/run-headless-server",
                },
                {
                  label: "Connect to a remote server",
                  slug: "manual/guides/connect-remote-server",
                },
              ],
            },
            {
              label: "Remote & mobile",
              items: [
                {
                  label: "Pair a device",
                  slug: "manual/guides/pair-a-device",
                },
              ],
            },
            {
              label: "Integrations",
              items: [
                {
                  label: "Set up GitHub integration",
                  slug: "manual/guides/github-integration",
                },
                {
                  label: "Set up Linear integration",
                  slug: "manual/guides/linear-integration",
                },
                {
                  label: "Use the MCP server",
                  slug: "manual/guides/mcp-server",
                },
                {
                  label: "Curate your newsfeed",
                  slug: "manual/guides/newsfeed",
                },
              ],
            },
            {
              label: "Settings",
              items: [
                {
                  label: "Configure notifications",
                  slug: "manual/guides/notifications",
                },
                {
                  label: "Manage adapters and models",
                  slug: "manual/guides/adapters",
                },
                {
                  label: "Configure sandbox policies",
                  slug: "manual/guides/sandbox-policies",
                },
                { label: "Manage API keys", slug: "manual/guides/api-keys" },
              ],
            },
          ],
        },
        {
          label: "Reference",
          items: [
            { label: "MCP tools", slug: "manual/reference/mcp-tools" },
            {
              label: "Agent configuration",
              slug: "manual/reference/agent-configuration",
            },
            {
              label: "Pipeline step kinds",
              slug: "manual/reference/pipeline-steps",
            },
            {
              label: "Ticket lifecycle",
              slug: "manual/reference/ticket-lifecycle",
            },
            {
              label: "Sandbox backends",
              slug: "manual/reference/sandbox-backends",
            },
            { label: "Domain events", slug: "manual/reference/domain-events" },
            {
              label: "Keyboard shortcuts",
              slug: "manual/reference/keyboard-shortcuts",
            },
            { label: "Route map", slug: "manual/reference/route-map" },
            { label: "Glossary", slug: "manual/reference/glossary" },
          ],
        },
      ],
    }),
    mdx(),
  ],

  vite: {
    plugins: [tailwindcss()],
  },

  adapter: cloudflare(),
});

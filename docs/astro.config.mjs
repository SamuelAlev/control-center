// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

import tailwindcss from "@tailwindcss/vite";

import mdx from "@astrojs/mdx";

import cloudflare from "@astrojs/cloudflare";

import {
  bundledComponents,
  dartDependencies,
} from "./src/data/third-party.build.mjs";
import { readFileSync, readdirSync } from "node:fs";

import { siteLocales, siteRtl } from "./src/data/locales.ts";

function thirdPartyManifest() {
  const id = "virtual:third-party";
  const resolved = "\0" + id;
  return {
    name: "cc-third-party-manifest",
    resolveId: (source) => (source === id ? resolved : null),
    load(source) {
      if (source !== resolved) return null;
      return [
        `export const components = ${JSON.stringify(bundledComponents())};`,
        `export const dartDeps = ${JSON.stringify(dartDependencies())};`,
      ].join("\n");
    },
  };
}


const site = "https://usectrl.dev";
const socialImage = new URL("/og.png", site).href;

const localeDirectory = new URL("./src/content/i18n/", import.meta.url);
const uiLocales = Object.fromEntries(
  readdirSync(localeDirectory).filter((file) => file.endsWith(".json")).map((file) => [
    file.slice(0, -5),
    JSON.parse(readFileSync(new URL(file, localeDirectory), "utf8")),
  ]),
);
const ui = uiLocales.en;
const socialImageAlt = ui["docs.socialImageAlt"];

/** @typedef {{label: string, slug?: string, collapsed?: boolean, items?: SidebarItem[]}} SidebarItem */
/** Resolve locale keys into Starlight's native label/translations fields.
 * @param {SidebarItem} item
 */
function localizeSidebar(item) {
  const key = item.label;
  return {
    ...item,
    label: ui[key],
    translations: Object.fromEntries(
      Object.entries(uiLocales).flatMap(([language, messages]) =>
        typeof messages[key] === "string" && messages[key] !== "" ? [[language, messages[key]]] : [],
      ),
    ),
    ...(item.items ? { items: item.items.map(localizeSidebar) } : {}),
  };
}

// https://astro.build/config
export default defineConfig({
  base: "/",
  site,

  integrations: [
    starlight({
      title: Object.fromEntries([
        ["en", ui["docs.siteTitle"]],
        ...siteLocales.map(({ id }) => [id, uiLocales[id]?.["docs.siteTitle"] || ui["docs.siteTitle"]]),
      ]),
      defaultLocale: "root",
      locales: Object.fromEntries(
        siteLocales.map(({ id, name }) => [
          id === "en-US" ? "root" : id,
          { label: name, lang: id === "en-US" ? "en" : id, dir: siteRtl.has(id) ? "rtl" : "ltr" },
        ]),
      ),
      customCss: ["./src/styles/starlight.css"],
      components: {
        Header: "./src/components/starlight/Header.astro",
        Footer: "./src/components/starlight/Footer.astro",
        LanguageSelect: "./src/components/starlight/LanguageSelect.astro",
        Sidebar: "./src/components/starlight/Sidebar.astro",
        ThemeSelect: "./src/components/starlight/ThemeSelect.astro",
        Head: "./src/components/starlight/Head.astro",
      },
      titleDelimiter: " \\\\ ",
      head: [
        { tag: "meta", attrs: { property: "og:image", content: socialImage } },
        { tag: "meta", attrs: { property: "og:image:width", content: "1200" } },
        { tag: "meta", attrs: { property: "og:image:height", content: "630" } },
        { tag: "meta", attrs: { property: "og:image:alt", content: socialImageAlt } },
        { tag: "meta", attrs: { name: "twitter:image", content: socialImage } },
        { tag: "meta", attrs: { name: "twitter:image:alt", content: socialImageAlt } },
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
      expressiveCode: {
        themes: ["github-light", "github-dark"],
        styleOverrides: {
          borderRadius: "0",
          borderColor: "var(--cc-border)",
          codeBackground: "var(--cc-rail)",
          codeFontFamily: "var(--cc-font-mono)",
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
          label: ui["docs.socialGitHub"],
          href: "https://github.com/SamuelAlev/control-center",
        },
      ],
      sidebar: [
        {
          label: "docs.sidebar.gettingStarted",
          items: [
            { label: "docs.sidebar.gettingStartedIntroduction", slug: "manual" },
            { label: "docs.sidebar.quickStart", slug: "manual/quick-start" },
            { label: "docs.sidebar.install", slug: "manual/install" },
          ],
        },
        {
          label: "docs.sidebar.tutorials",
          items: [
            { label: "docs.sidebar.tutorialsOverview", slug: "manual/tutorials" },
            {
              label: "docs.sidebar.tutorialsFirstWorkspace",
              slug: "manual/tutorials/first-workspace",
            },
            {
              label: "docs.sidebar.tutorialsFirstAgent",
              slug: "manual/tutorials/first-agent",
            },
            {
              label: "docs.sidebar.tutorialsFirstPr",
              slug: "manual/tutorials/first-pr",
            },
            {
              label: "docs.sidebar.tutorialsFirstPipeline",
              slug: "manual/tutorials/first-pipeline",
            },
            {
              label: "docs.sidebar.tutorialsFirstChatBridge",
              slug: "manual/tutorials/first-chat-bridge",
            },
            {
              label: "docs.sidebar.tutorialsSso",
              slug: "manual/tutorials/sso",
            },
          ],
        },
        {
          label: "docs.sidebar.concepts",
          items: [
            { label: "docs.sidebar.conceptsOverview", slug: "manual/concepts" },
            {
              label: "docs.sidebar.conceptsCoreModel",
              items: [
                {
                  label: "docs.sidebar.conceptsWorkspaces",
                  slug: "manual/concepts/workspaces",
                },
                {
                  label: "docs.sidebar.conceptsAgentModel",
                  slug: "manual/concepts/agent-model",
                },
                {
                  label: "docs.sidebar.conceptsDispatchLifecycle",
                  slug: "manual/concepts/dispatch-lifecycle",
                },
                { label: "docs.sidebar.conceptsModes", slug: "manual/concepts/modes" },
                {
                  label: "docs.sidebar.conceptsToolContext",
                  slug: "manual/concepts/tool-context",
                },
                {
                  label: "docs.sidebar.conceptsConversationHistory",
                  slug: "manual/concepts/conversation-history",
                },
                {
                  label: "docs.sidebar.conceptsCodeIntelligence",
                  slug: "manual/concepts/code-intelligence",
                },
              ],
            },
            {
              label: "docs.sidebar.conceptsSafetyAndControl",
              items: [
                {
                  label: "docs.sidebar.conceptsSandboxSecurity",
                  slug: "manual/concepts/sandbox-security",
                },
                { label: "docs.sidebar.conceptsGuardrails", slug: "manual/concepts/guardrails" },
                {
                  label: "docs.sidebar.conceptsAuthorization",
                  slug: "manual/concepts/authorization",
                },
                {
                  label: "docs.sidebar.conceptsRigs",
                  slug: "manual/concepts/rigs",
                },
              ],
            },
            {
              label: "docs.sidebar.conceptsDirectingTheWork",
              items: [
                {
                  label: "docs.sidebar.conceptsTickets",
                  slug: "manual/concepts/tickets",
                },
                {
                  label: "docs.sidebar.conceptsPipelines",
                  slug: "manual/concepts/pipelines",
                },
                {
                  label: "docs.sidebar.conceptsOrchestration",
                  slug: "manual/concepts/orchestration",
                },
                {
                  label: "docs.sidebar.conceptsAiReview",
                  slug: "manual/concepts/ai-review",
                },
                {
                  label: "docs.sidebar.conceptsMemoryKnowledge",
                  slug: "manual/concepts/memory-knowledge",
                },
                {
                  label: "docs.sidebar.conceptsEvalsAndQuality",
                  slug: "manual/concepts/evals-and-quality",
                },
              ],
            },
            {
              label: "docs.sidebar.conceptsPeopleAndReach",
              items: [
                {
                  label: "docs.sidebar.conceptsMultiplayer",
                  slug: "manual/concepts/multiplayer",
                },
                { label: "docs.sidebar.conceptsSso", slug: "manual/concepts/sso" },
                {
                  label: "docs.sidebar.conceptsChatBridges",
                  slug: "manual/concepts/chat-bridges",
                },
                {
                  label: "docs.sidebar.conceptsPrConversations",
                  slug: "manual/concepts/pr-conversations",
                },
                {
                  label: "docs.sidebar.conceptsRemoteControl",
                  slug: "manual/concepts/remote-control",
                },
                {
                  label: "docs.sidebar.conceptsMeetings",
                  slug: "manual/concepts/meetings",
                },
                {
                  label: "docs.sidebar.conceptsCalendar",
                  slug: "manual/concepts/calendar",
                },
              ],
            },
            {
              label: "docs.sidebar.conceptsUnderTheHood",
              items: [
                {
                  label: "docs.sidebar.conceptsArchitecture",
                  slug: "manual/concepts/architecture",
                },
                {
                  label: "docs.sidebar.conceptsDeployment",
                  slug: "manual/concepts/deployment",
                },
                {
                  label: "docs.sidebar.conceptsDomainEvents",
                  slug: "manual/concepts/domain-events",
                },
              ],
            },
          ],
        },
        {
          label: "docs.sidebar.guides",
          items: [
            { label: "docs.sidebar.guidesOverview", slug: "manual/guides" },
            {
              label: "docs.sidebar.guidesAgents",
              items: [
                {
                  label: "docs.sidebar.guidesCreateAgent",
                  slug: "manual/guides/create-agent",
                },
                {
                  label: "docs.sidebar.guidesParallelAgents",
                  slug: "manual/guides/parallel-agents",
                },
                {
                  label: "docs.sidebar.guidesBuildTeam",
                  slug: "manual/guides/build-team",
                },
                {
                  label: "docs.sidebar.guidesManageCosts",
                  slug: "manual/guides/manage-costs",
                },
                {
                  label: "docs.sidebar.guidesAgentDiagnostics",
                  slug: "manual/guides/agent-diagnostics",
                },
                {
                  label: "docs.sidebar.guidesTuneToolContext",
                  slug: "manual/guides/tune-tool-context",
                },
                {
                  label: "docs.sidebar.guidesDebugAFailingTest",
                  slug: "manual/guides/debug-a-failing-test",
                },
                {
                  label: "docs.sidebar.guidesExploreDataInAKernel",
                  slug: "manual/guides/explore-data-in-a-kernel",
                },
                {
                  label: "docs.sidebar.guidesDirectBackgroundWorkers",
                  slug: "manual/guides/direct-background-workers",
                },
              ],
            },
            {
              label: "docs.sidebar.guidesWorkspaces",
              items: [
                {
                  label: "docs.sidebar.guidesAddRepos",
                  slug: "manual/guides/add-repos",
                },
                {
                  label: "docs.sidebar.guidesRepoScripts",
                  slug: "manual/guides/repo-scripts",
                },
                {
                  label: "docs.sidebar.guidesManageMemory",
                  slug: "manual/guides/manage-memory",
                },
                {
                  label: "docs.sidebar.guidesManageSkills",
                  slug: "manual/guides/manage-skills",
                },
                {
                  label: "docs.sidebar.guidesCodeSearch",
                  slug: "manual/guides/code-search",
                },
                {
                  label: "docs.sidebar.guidesStructuralRefactor",
                  slug: "manual/guides/structural-refactor",
                },
                {
                  label: "docs.sidebar.guidesUseRigs",
                  slug: "manual/guides/use-rigs",
                },
                {
                  label: "docs.sidebar.guidesVmPorts",
                  slug: "manual/guides/vm-ports",
                },
              ],
            },
            {
              label: "docs.sidebar.guidesPullRequests",
              items: [
                {
                  label: "docs.sidebar.guidesReviewMergePr",
                  slug: "manual/guides/review-merge-pr",
                },
                {
                  label: "docs.sidebar.guidesAiReview",
                  slug: "manual/guides/ai-review",
                },
                {
                  label: "docs.sidebar.guidesGithubPrConversations",
                  slug: "manual/guides/github-pr-conversations",
                },
                {
                  label: "docs.sidebar.guidesDispatchReviewers",
                  slug: "manual/guides/dispatch-reviewers",
                },
                {
                  label: "docs.sidebar.guidesReviewCompute",
                  slug: "manual/guides/review-compute",
                },
              ],
            },
            {
              label: "docs.sidebar.guidesMessaging",
              items: [
                {
                  label: "docs.sidebar.guidesChatWithAgent",
                  slug: "manual/guides/chat-with-agent",
                },
                {
                  label: "docs.sidebar.guidesSpaces",
                  slug: "manual/guides/spaces",
                },
                {
                  label: "docs.sidebar.guidesMentionAgents",
                  slug: "manual/guides/mention-agents",
                },
                { label: "docs.sidebar.guidesPlanMode", slug: "manual/guides/plan-mode" },
                {
                  label: "docs.sidebar.guidesBranchAConversation",
                  slug: "manual/guides/branch-a-conversation",
                },
                {
                  label: "docs.sidebar.guidesTriageInbox",
                  slug: "manual/guides/triage-inbox",
                },
              ],
            },
            {
              label: "docs.sidebar.guidesPipelinesAndPlans",
              items: [
                {
                  label: "docs.sidebar.guidesCreatePipeline",
                  slug: "manual/guides/create-pipeline",
                },
                {
                  label: "docs.sidebar.guidesRunPipeline",
                  slug: "manual/guides/run-pipeline",
                },
                {
                  label: "docs.sidebar.guidesPipelineTriggers",
                  slug: "manual/guides/pipeline-triggers",
                },
                {
                  label: "docs.sidebar.guidesMonitorPipelines",
                  slug: "manual/guides/monitor-pipelines",
                },
                {
                  label: "docs.sidebar.guidesRunOrchestration",
                  slug: "manual/guides/run-orchestration",
                },
                {
                  label: "docs.sidebar.guidesPlanStudio",
                  slug: "manual/guides/plan-studio",
                },
              ],
            },
            {
              label: "docs.sidebar.guidesTicketing",
              items: [
                {
                  label: "docs.sidebar.guidesManageTickets",
                  slug: "manual/guides/manage-tickets",
                },
                {
                  label: "docs.sidebar.guidesDelegateTickets",
                  slug: "manual/guides/delegate-tickets",
                },
                {
                  label: "docs.sidebar.guidesProjects",
                  slug: "manual/guides/projects",
                },
              ],
            },
            {
              label: "docs.sidebar.guidesMeetingsAndCalendar",
              items: [
                {
                  label: "docs.sidebar.guidesRecordMeeting",
                  slug: "manual/guides/record-meeting",
                },
                {
                  label: "docs.sidebar.guidesConnectCalendar",
                  slug: "manual/guides/connect-calendar",
                },
              ],
            },
            {
              label: "docs.sidebar.guidesServerAndDeployment",
              items: [
                {
                  label: "docs.sidebar.guidesRunHeadlessServer",
                  slug: "manual/guides/run-headless-server",
                },
                {
                  label: "docs.sidebar.guidesConnectRemoteServer",
                  slug: "manual/guides/connect-remote-server",
                },
                {
                  label: "docs.sidebar.guidesRunFleetWorker",
                  slug: "manual/guides/run-fleet-worker",
                },
                {
                  label: "docs.sidebar.guidesBackUpAndRestore",
                  slug: "manual/guides/back-up-and-restore",
                },
                {
                  label: "docs.sidebar.guidesPairADevice",
                  slug: "manual/guides/pair-a-device",
                },
                {
                  label: "docs.sidebar.guidesSsoOidc",
                  slug: "manual/guides/sso-oidc",
                },
                {
                  label: "docs.sidebar.guidesSsoScim",
                  slug: "manual/guides/sso-scim",
                },
              ],
            },
            {
              label: "docs.sidebar.guidesIntegrations",
              items: [
                {
                  label: "docs.sidebar.guidesConnectForges",
                  slug: "manual/guides/connect-forges",
                },
                {
                  label: "docs.sidebar.guidesGithubIntegration",
                  slug: "manual/guides/github-integration",
                },
                {
                  label: "docs.sidebar.guidesGithubApp",
                  slug: "manual/guides/github-app",
                },
                {
                  label: "docs.sidebar.guidesLinearIntegration",
                  slug: "manual/guides/linear-integration",
                },
                {
                  label: "docs.sidebar.guidesSlackIntegration",
                  slug: "manual/guides/slack-integration",
                },
                {
                  label: "docs.sidebar.guidesLinkChatAccount",
                  slug: "manual/guides/link-chat-account",
                },
                {
                  label: "docs.sidebar.guidesCustomizeChatBot",
                  slug: "manual/guides/customize-chat-bot",
                },
                {
                  label: "docs.sidebar.guidesMcpServer",
                  slug: "manual/guides/mcp-server",
                },
                {
                  label: "docs.sidebar.guidesNewsfeed",
                  slug: "manual/guides/newsfeed",
                },
              ],
            },
            {
              label: "docs.sidebar.guidesYourEnvironment",
              items: [
                {
                  label: "docs.sidebar.guidesNotifications",
                  slug: "manual/guides/notifications",
                },
                {
                  label: "docs.sidebar.guidesFocusMode",
                  slug: "manual/guides/focus-mode",
                },
                {
                  label: "docs.sidebar.guidesAdapters",
                  slug: "manual/guides/adapters",
                },
                {
                  label: "docs.sidebar.guidesSandboxPolicies",
                  slug: "manual/guides/sandbox-policies",
                },
                {
                  label: "docs.sidebar.guidesConfigureGuardrails",
                  slug: "manual/guides/configure-guardrails",
                },
                { label: "docs.sidebar.guidesApiKeys", slug: "manual/guides/api-keys" },
              ],
            },
          ],
        },
        {
          label: "docs.sidebar.reference",
          items: [
            { label: "docs.sidebar.referenceOverview", slug: "manual/reference" },
            { label: "docs.sidebar.referenceMcpTools", slug: "manual/reference/mcp-tools" },
            {
              label: "docs.sidebar.referenceAgentTools",
              slug: "manual/reference/agent-tools",
            },
            {
              label: "docs.sidebar.referenceSlashCommands",
              slug: "manual/reference/slash-commands",
            },
            {
              label: "docs.sidebar.referenceSso",
              slug: "manual/reference/sso",
            },
            {
              label: "docs.sidebar.referenceAgentConfiguration",
              slug: "manual/reference/agent-configuration",
            },
            {
              label: "docs.sidebar.referencePipelineSteps",
              slug: "manual/reference/pipeline-steps",
            },
            {
              label: "docs.sidebar.referenceTicketLifecycle",
              slug: "manual/reference/ticket-lifecycle",
            },
            {
              label: "docs.sidebar.referenceSandboxBackends",
              slug: "manual/reference/sandbox-backends",
            },
            { label: "docs.sidebar.referenceRigs", slug: "manual/reference/rigs" },
            { label: "docs.sidebar.referenceChatBridge", slug: "manual/reference/chat-bridge" },
            { label: "docs.sidebar.referenceDomainEvents", slug: "manual/reference/domain-events" },
            {
              label: "docs.sidebar.referenceKeyboardShortcuts",
              slug: "manual/reference/keyboard-shortcuts",
            },
            { label: "docs.sidebar.referenceRouteMap", slug: "manual/reference/route-map" },
            {
              label: "docs.sidebar.referenceCcServerCli",
              slug: "manual/reference/cc-server-cli",
            },
            {
              label: "docs.sidebar.referenceBackup",
              slug: "manual/reference/backup",
            },
            { label: "docs.sidebar.referenceGlossary", slug: "manual/reference/glossary" },
          ],
        },
      ].map(localizeSidebar),
    }),
    mdx(),
  ],

  vite: {
    plugins: [tailwindcss(), thirdPartyManifest()],
  },

  adapter: cloudflare(),
});

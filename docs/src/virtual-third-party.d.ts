/**
 * Types for the build-time `virtual:third-party` module.
 *
 * The module is produced by the `cc-third-party-manifest` Vite plugin in
 * `astro.config.mjs`, which parses `scripts/lib/third_party.sh` and
 * `third_party/licenses/` on the build host and inlines the result. It has no
 * file on disk, so its shape is declared here.
 */
declare module 'virtual:third-party' {
  export interface BundledComponent {
    /** Anchor-safe id, e.g. `tree-sitter-php`. */
    slug: string;
    /** Display name, e.g. `LAME (libmp3lame)`. */
    name: string;
    /** Resolved version: a release string, or a shortened git pin. */
    version: string;
    /** SPDX identifier, e.g. `Apache-2.0`. */
    license: string;
    /** Upstream project URL. */
    homepage: string;
    /** How the artifact carries it. */
    linkage: 'static' | 'dynamic' | 'bundled';
    /** Which artifacts carry it: `desktop`, `server`, or both. */
    roles: string[];
    /** The full license text, verbatim. */
    text: string;
  }

  export interface DartDependency {
    name: string;
    version: string;
    /** pub.dev page, or the hosted URL when it is not pub.dev. */
    url: string;
  }

  export const components: BundledComponent[];
  export const dartDeps: DartDependency[];
}

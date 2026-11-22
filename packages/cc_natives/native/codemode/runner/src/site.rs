//! The script's text as the runner compiles it, and the conversion of a
//! position QuickJS reports into a call's `at` (README.md, `call`).
//!
//! QuickJS-NG reports a frame's position as the line of the compiled source
//! (1-based) and the column in UTF-8 bytes from the start of that line
//! (1-based). The compiled source is [`SCRIPT_HEAD`] + script +
//! [`SCRIPT_TAIL`], so script line N is reported as N + 2. `at` carries the
//! script's own 1-based line and a 1-based column in UTF-16 code units, the
//! unit JavaScript and Dart index strings by.
//!
//! Lines are split at `\n`, `\r\n` and a lone `\r`, which is how QuickJS
//! counts them everywhere in a script (code, comments, strings, templates).
//! U+2028 and U+2029 are line terminators to QuickJS in code but not inside
//! a comment, so a script containing either gets no sites at all: a line
//! number could not be mapped back with certainty.

use std::rc::Rc;

/// What the runner puts before the script: the AsyncFunction constructor's
/// own wrapping, so the script is parsed exactly as `new AsyncFunction(code)`
/// would parse it.
pub const SCRIPT_HEAD: &str = "(async function anonymous(\n) {\n";

/// What the runner puts after the script.
pub const SCRIPT_TAIL: &str = "\n})";

/// File name the script is compiled under. Code a script makes with `eval`
/// or `Function` is compiled by QuickJS as `<input>`, so its frames are never
/// mistaken for the script's own. The prelude maps `<script>:L:C` to
/// `repl.js:L-2:C` in the stacks it reports; a stack the script reads itself
/// keeps the engine's numbering under this name.
pub const SCRIPT_FILE: &std::ffi::CStr = c"<script>";

/// Lines of [`SCRIPT_HEAD`].
const HEAD_LINES: u64 = 2;

/// Bytes between two UTF-16 checkpoints of the index: converting a column
/// reads at most this many bytes (plus one character) twice, however long
/// the line or the script.
const STRIDE: usize = 1024;

/// What makes a lookup independent of the script's length, built once with
/// the script: where each line starts (4 bytes a line), and every [`STRIDE`]
/// bytes the UTF-16 units before that point (8 bytes a KiB). The runner's own
/// allocations stay a small multiple of the frame the script came in.
struct Index {
    line_starts: Vec<u32>,
    checkpoints: Vec<(u32, u32)>,
}

impl Index {
    fn new(text: &str) -> Index {
        let b = text.as_bytes();
        let breaks = b.iter().filter(|c| **c == b'\n' || **c == b'\r').count();
        let mut line_starts = Vec::with_capacity(breaks + 1);
        line_starts.push(0u32);
        let mut i = 0;
        while i < b.len() {
            match b[i] {
                b'\n' => line_starts.push(i as u32 + 1),
                b'\r' if b.get(i + 1) == Some(&b'\n') => {
                    i += 1;
                    line_starts.push(i as u32 + 1);
                }
                b'\r' => line_starts.push(i as u32 + 1),
                _ => {}
            }
            i += 1;
        }
        // Checkpoint k is the first character boundary at or past k * STRIDE.
        let mut checkpoints = Vec::with_capacity(b.len() / STRIDE + 1);
        let (mut units, mut next) = (0u32, 0usize);
        for (at, c) in text.char_indices() {
            if at >= next {
                checkpoints.push((at as u32, units));
                next = (at / STRIDE + 1) * STRIDE;
            }
            units += c.len_utf16() as u32;
        }
        Index { line_starts, checkpoints }
    }

    /// The UTF-16 units of `text` before byte `at` (a character boundary),
    /// and how many bytes were read to count them.
    fn units_before(&self, text: &str, at: usize) -> (u64, usize) {
        let Some(last) = self.checkpoints.len().checked_sub(1) else {
            return (0, 0);
        };
        let mut k = (at / STRIDE).min(last);
        if self.checkpoints[k].0 as usize > at {
            k -= 1;
        }
        let (from, units) = self.checkpoints[k];
        let part = &text[from as usize..at];
        (units as u64 + part.encode_utf16().count() as u64, part.len())
    }
}

/// The script of this session.
pub struct Script {
    text: Rc<str>,
    sites: bool,
    index: Index,
}

impl Script {
    pub fn new(text: String) -> Script {
        let sites = !text.contains(['\u{2028}', '\u{2029}']) && text.len() <= u32::MAX as usize;
        let index = if sites {
            Index::new(&text)
        } else {
            Index { line_starts: Vec::new(), checkpoints: Vec::new() }
        };
        Script {
            text: Rc::from(text),
            sites,
            index,
        }
    }

    pub fn text(&self) -> Rc<str> {
        self.text.clone()
    }

    /// The `at` for a position QuickJS reported, or `None` when the
    /// position is not a character of the script's own text: not two
    /// integers, inside the wrapping, past the end of a line or the script,
    /// in the middle of a character, or a script with U+2028/U+2029.
    ///
    /// Constant in the script's length and the line's: a line lookup and two
    /// counts of at most [`STRIDE`] bytes and a character.
    pub fn site(&self, engine_line: f64, engine_column: f64) -> Option<(u64, u64)> {
        self.site_reading(engine_line, engine_column).0
    }

    /// [`Script::site`], and how many bytes of the script it read.
    fn site_reading(&self, engine_line: f64, engine_column: f64) -> (Option<(u64, u64)>, usize) {
        if !self.sites {
            return (None, 0);
        }
        let whole = |v: f64| v.is_finite() && v.fract() == 0.0 && v >= 1.0 && v <= u32::MAX as f64;
        if !whole(engine_line) || !whole(engine_column) {
            return (None, 0);
        }
        let (engine_line, column_bytes) = (engine_line as u64, engine_column as usize);
        if engine_line <= HEAD_LINES {
            return (None, 0);
        }
        let line = engine_line - HEAD_LINES;
        let text = &*self.text;
        let b = text.as_bytes();
        let index = &self.index;
        let starts = &index.line_starts;
        let Some(&start) = starts.get(line as usize - 1) else {
            return (None, 0);
        };
        let start = start as usize;
        // The line ends before the break the next line starts after.
        let end = match starts.get(line as usize) {
            None => b.len(),
            Some(&next) => {
                let next = next as usize;
                if next >= 2 && b[next - 2] == b'\r' && b[next - 1] == b'\n' {
                    next - 2
                } else {
                    next - 1
                }
            }
        };
        let at = start + (column_bytes - 1);
        if at >= end || !text.is_char_boundary(at) {
            return (None, 0);
        }
        let (before_line, read_line) = index.units_before(text, start);
        let (before_call, read_call) = index.units_before(text, at);
        (Some((line, before_call - before_line + 1)), read_line + read_call)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn site(text: &str, line: f64, column: f64) -> Option<(u64, u64)> {
        Script::new(text.to_string()).site(line, column)
    }

    #[test]
    fn maps_lines_past_the_wrapping() {
        assert_eq!(site("a()", 3.0, 1.0), Some((1, 1)));
        assert_eq!(site("x;\n  a()", 4.0, 3.0), Some((2, 3)));
        assert_eq!(site("a()", 2.0, 1.0), None);
        assert_eq!(site("a()", 1.0, 1.0), None);
    }

    #[test]
    fn splits_lines_the_way_quickjs_counts_them() {
        let text = "l1\r\nl2\rl3\nl4";
        assert_eq!(site(text, 4.0, 1.0), Some((2, 1)));
        assert_eq!(site(text, 5.0, 2.0), Some((3, 2)));
        assert_eq!(site(text, 6.0, 2.0), Some((4, 2)));
        assert_eq!(site(text, 7.0, 1.0), None);
        // A blank line after CRLF is a line of its own.
        assert_eq!(site("a\r\n\r\nb", 5.0, 1.0), Some((3, 1)));
    }

    #[test]
    fn converts_byte_columns_to_utf16_units() {
        // é is 2 bytes and 1 unit, € 3 and 1, 😀 4 and 2.
        let text = "x = \"é€😀\"; f()";
        let bytes = text.find('f').unwrap() + 1;
        assert_eq!(site(text, 3.0, bytes as f64), Some((1, 13)));
        // The middle of a character is not a position.
        let inside = text.find('é').unwrap() + 2;
        assert_eq!(site(text, 3.0, inside as f64), None);
    }

    #[test]
    fn refuses_positions_outside_the_text() {
        assert_eq!(site("ab", 3.0, 3.0), None);
        assert_eq!(site("ab\ncd", 3.0, 3.0), None);
        assert_eq!(site("ab", 3.0, 0.0), None);
        assert_eq!(site("ab", 3.0, -1.0), None);
        assert_eq!(site("ab", 3.0, 1.5), None);
        assert_eq!(site("ab", f64::NAN, 1.0), None);
        assert_eq!(site("ab", 3.0, f64::INFINITY), None);
        assert_eq!(site("ab", 5e9, 1.0), None);
        assert_eq!(site("", 3.0, 1.0), None);
    }

    #[test]
    fn a_script_with_unicode_line_separators_has_no_sites() {
        assert_eq!(site("a()\u{2028}b()", 3.0, 1.0), None);
        assert_eq!(site("/* \u{2029} */ a()", 3.0, 1.0), None);
    }

    #[test]
    fn a_lookup_reads_a_bounded_part_of_the_script_whatever_its_shape() {
        // The reviewer's shapes: a call behind a 1 MiB line, behind 256 KiB
        // of newlines, before a 1 MiB comment on its own line, and behind
        // 1 MiB of astral characters on one line.
        let call = "await tools.read({});";
        let big = "x".repeat(1 << 20);
        let astral = "\u{1F600}".repeat(1 << 18);
        let shapes = [
            (format!("/*{big}*/ {call}"), 3.0, big.len() + 6),
            (format!("/*{big}*/\n{call}"), 4.0, 13),
            (format!("{}{call}", "\n".repeat(1 << 18)), 3.0 + (1 << 18) as f64, 13),
            (format!("{call} /*{big}*/"), 3.0, 13),
            (format!("/*{astral}*/ {call}"), 3.0, astral.len() + 6),
        ];
        let bound = 2 * (STRIDE + 3);
        for (text, line, column) in shapes {
            let script = Script::new(text);
            for _ in 0..5000 {
                let (at, read) = script.site_reading(line, column as f64);
                assert!(at.is_some(), "line {line} column {column}");
                assert!(read <= bound, "read {read} bytes");
            }
        }
        // The astral line: 2^18 characters of 2 units each before the call.
        let script = Script::new(format!("/*{astral}*/ f()"));
        assert_eq!(
            script.site(3.0, (astral.len() + 6) as f64),
            Some((1, (1 << 19) + 6))
        );
    }

    #[test]
    fn checkpoints_land_on_character_boundaries() {
        // A 3-byte character straddles every STRIDE boundary.
        let text = format!("{}f()", "\u{20AC}".repeat(STRIDE));
        let column = text.find('f').unwrap() + 1;
        assert_eq!(site(&text, 3.0, column as f64), Some((1, STRIDE as u64 + 1)));
        let text = format!("a{}\nf()", "\u{20AC}".repeat(STRIDE));
        assert_eq!(site(&text, 4.0, 1.0), Some((2, 1)));
    }
}

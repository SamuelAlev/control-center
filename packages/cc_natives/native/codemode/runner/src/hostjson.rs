//! Sizes as the host measures them.
//!
//! The host decodes a frame with Dart's `jsonDecode` and measures a call's
//! arguments and a stored value as the UTF-8 length of Dart's `jsonEncode`
//! of the decoded value. That is not the length of the JavaScript text the
//! script produced: Dart decodes an integer outside the 64-bit range as a
//! double and writes every integral double below 10^21 with a trailing `.0`
//! (`1e20` becomes `100000000000000000000.0`). A value the runner admitted
//! by its JavaScript length could therefore be over the host's cap, and the
//! host ends a session that sends one. The runner measures with these rules
//! instead, so what it admits the host admits.

use serde_json::{Number, Value as Json};

/// UTF-8 length of Dart's `jsonEncode` of `v` (compact, no whitespace).
pub fn dart_len(v: &Json) -> u64 {
    match v {
        Json::Null | Json::Bool(true) => 4,
        Json::Bool(false) => 5,
        Json::Number(n) => number_len(n),
        Json::String(s) => string_len(s),
        Json::Array(items) => {
            2 + items.iter().map(dart_len).sum::<u64>() + items.len().saturating_sub(1) as u64
        }
        Json::Object(map) => {
            2 + map
                .iter()
                .map(|(k, v)| string_len(k) + 1 + dart_len(v))
                .sum::<u64>()
                + map.len().saturating_sub(1) as u64
        }
    }
}

/// A JSON string with quotes, escaped as Dart escapes it: `"` and `\`, the
/// five short control escapes, `\u00XX` for the other control characters,
/// everything else as UTF-8.
fn string_len(s: &str) -> u64 {
    2 + s
        .bytes()
        .map(|b| match b {
            b'"' | b'\\' | b'\n' | b'\r' | b'\t' | 0x08 | 0x0c => 2,
            0..=0x1f => 6,
            _ => 1,
        })
        .sum::<u64>()
}

fn number_len(n: &Number) -> u64 {
    if let Some(i) = n.as_i64() {
        // A Dart int: its decimal digits.
        return i.to_string().len() as u64;
    }
    // A u64 above i64::MAX, or a float: a Dart double either way.
    double_len(n.as_f64().unwrap_or(0.0))
}

/// Length of Dart's `double.toString()`: the shortest digits that read back
/// as the same double, laid out as JavaScript lays out a number, except that
/// an integral value below 10^21 gets `.0`.
fn double_len(x: f64) -> u64 {
    let sign = u64::from(x.is_sign_negative());
    // `{:e}` gives the shortest round-trip digits: `1.5e-7`, `1e20`.
    let sci = format!("{:e}", x.abs());
    let (mantissa, exp) = sci.split_once('e').unwrap_or((&sci, "0"));
    let exp: i64 = exp.parse().unwrap_or(0);
    let k = mantissa.bytes().filter(u8::is_ascii_digit).count() as i64;
    // Position of the decimal point relative to the digits.
    let n = exp + 1;
    let body = if x.fract() == 0.0 && x.abs() < 1e21 {
        // Every digit before the point, padded with zeros, then ".0".
        n.max(1) + 2
    } else if 0 < n && n <= 21 {
        // Digits with a point inside (never integral here).
        k.max(n) + 1
    } else if -6 < n && n <= 0 {
        // "0." then -n zeros then the digits.
        2 - n + k
    } else {
        // d[.ddd]e±x
        let e = n - 1;
        k + i64::from(k > 1) + 2 + e.abs().to_string().len() as i64
    };
    sign + body as u64
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Each case is a number as the runner writes it and Dart's
    /// `jsonEncode(jsonDecode(...))` of it, measured with `fvm dart run`.
    #[test]
    fn numbers_match_dart() {
        for (json, dart) in [
            ("1e+20", "100000000000000000000.0"),
            ("100000000000000000000", "100000000000000000000.0"),
            ("18000000000000000000", "18000000000000000000.0"),
            ("9223372036854776000", "9223372036854776000.0"),
            ("9007199254740993", "9007199254740993"),
            ("1e+21", "1e+21"),
            ("1.5e-7", "1.5e-7"),
            ("-0.0", "-0.0"),
            ("0.1", "0.1"),
            ("100.0", "100.0"),
            ("100.5", "100.5"),
            ("5e-324", "5e-324"),
            ("1.7976931348623157e308", "1.7976931348623157e+308"),
            ("123456789012345680000", "123456789012345680000.0"),
            ("1e-7", "1e-7"),
            ("0.000001", "0.000001"),
            ("1.23e-18", "1.23e-18"),
            ("-42", "-42"),
            ("-1e+20", "-100000000000000000000.0"),
            ("12.5e3", "12500.0"),
        ] {
            let v: Json = serde_json::from_str(json).unwrap();
            assert_eq!(dart_len(&v), dart.len() as u64, "{json} -> {dart}");
        }
    }

    #[test]
    fn strings_and_containers_match_dart() {
        // Dart: jsonEncode("a\u0001\u007f \"\\\n\t\b\f\r\u001f")
        //   == "a\u0001\x7f \"\\\n\t\b\f\r\u001f" (raw DEL and U+2028).
        let v = Json::String("a\u{1}\u{7f}\u{2028}\"\\\n\t\u{8}\u{c}\r\u{1f}".into());
        assert_eq!(dart_len(&v), 2 + 1 + 6 + 1 + 3 + 2 + 2 + 2 + 2 + 2 + 2 + 2 + 6);
        let v: Json = serde_json::from_str(r#"{"a":[1,null,true,false,"x"],"b":{}}"#).unwrap();
        assert_eq!(dart_len(&v), r#"{"a":[1,null,true,false,"x"],"b":{}}"#.len() as u64);
        assert_eq!(dart_len(&serde_json::json!([])), 2);
    }
}

use std::error::Error;
use std::fs::File;
use std::io::{self, Read, Write};
use std::path::Path;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::Arc;

use resvg::{tiny_skia, usvg};

// Bound input before XML parsing; the Dart caller bounds and stores encoded output.
const MAX_SOURCE_BYTES: u64 = 8 * 1024 * 1024;
const MAX_DIMENSION: u32 = 2048;
const MAX_EMBEDDED_BYTES: usize = 4 * 1024 * 1024;
const MAX_EMBEDDED_PIXELS: usize = 4 * 1024 * 1024;

fn main() {
    if let Err(error) = run() {
        eprintln!("cc_svg_render: {error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn Error>> {
    if std::env::args_os().nth(1).as_deref() == Some(std::ffi::OsStr::new("--version")) {
        println!("cc_svg_render {} (resvg 0.48.1)", env!("CARGO_PKG_VERSION"));
        return Ok(());
    }
    let mut args = std::env::args_os();
    let program = args.next().unwrap_or_default();
    let (Some(command), Some(path), Some(dimension)) = (args.next(), args.next(), args.next())
    else {
        return Err(format!(
            "usage: {} render ABSOLUTE_LOCAL_PATH MAX_DIMENSION",
            program.to_string_lossy()
        )
        .into());
    };
    if command != "render" || args.next().is_some() {
        return Err("usage: cc_svg_render render ABSOLUTE_LOCAL_PATH MAX_DIMENSION".into());
    }
    let path = Path::new(&path);
    if !path.is_absolute() {
        return Err("SVG input path must be absolute".into());
    }
    let dimension: u32 = dimension
        .to_str()
        .ok_or("invalid maximum dimension")?
        .parse()?;
    if !(1..=MAX_DIMENSION).contains(&dimension) {
        return Err(format!("maximum dimension must be between 1 and {MAX_DIMENSION}").into());
    }

    let input = File::open(path)?;
    if input.metadata()?.len() > MAX_SOURCE_BYTES {
        return Err("SVG source exceeds 8 MiB".into());
    }
    let mut data = Vec::new();
    input.take(MAX_SOURCE_BYTES + 1).read_to_end(&mut data)?;
    if data.len() as u64 > MAX_SOURCE_BYTES {
        return Err("SVG source exceeds 8 MiB".into());
    }
    // SVGZ is not accepted: decompression before validation would evade the source limit.
    let xml = std::str::from_utf8(&data).map_err(|_| "SVG must be UTF-8 XML")?;
    let has_text = validate_resources(xml)?;

    let mut options = usvg::Options::default();
    options.resources_dir = None;
    // Never use usvg's default string resolver (it reads local files), nor its
    // default data resolver (it recursively parses SVG images). Only bounded
    // in-document PNG and JPEG bytes can reach the raster decoder.
    let invalid_image = Arc::new(AtomicBool::new(false));
    let invalid_image_in_resolver = Arc::clone(&invalid_image);
    let embedded_bytes = AtomicUsize::new(0);
    let embedded_pixels = AtomicUsize::new(0);
    options.image_href_resolver = usvg::ImageHrefResolver {
        resolve_string: Box::new(|_, _| None),
        resolve_data: Box::new(move |mime, data, _| {
            if data.len() > MAX_EMBEDDED_BYTES {
                invalid_image_in_resolver.store(true, Ordering::Relaxed);
                return None;
            }
            let png = match (mime, imagesize::image_type(&data)) {
                ("image/png", Ok(imagesize::ImageType::Png)) => true,
                ("image/jpeg" | "image/jpg", Ok(imagesize::ImageType::Jpeg)) => false,
                _ => {
                    invalid_image_in_resolver.store(true, Ordering::Relaxed);
                    return None;
                }
            };
            let size = match imagesize::blob_size(&data) {
                Ok(size) => size,
                Err(_) => {
                    invalid_image_in_resolver.store(true, Ordering::Relaxed);
                    return None;
                }
            };
            let Some(pixels) = size.width.checked_mul(size.height) else {
                invalid_image_in_resolver.store(true, Ordering::Relaxed);
                return None;
            };
            if size.width == 0
                || size.height == 0
                || size.width > 4096
                || size.height > 4096
                || pixels > MAX_EMBEDDED_PIXELS
                || embedded_bytes.fetch_add(data.len(), Ordering::Relaxed)
                    > MAX_EMBEDDED_BYTES - data.len()
                || embedded_pixels.fetch_add(pixels, Ordering::Relaxed)
                    > MAX_EMBEDDED_PIXELS - pixels
            {
                invalid_image_in_resolver.store(true, Ordering::Relaxed);
                return None;
            }
            Some(if png {
                usvg::ImageKind::PNG(data)
            } else {
                usvg::ImageKind::JPEG(data)
            })
        }),
    };
    if has_text {
        let executable = std::env::current_exe()?;
        let fonts = executable
            .parent()
            .ok_or("SVG renderer directory is missing")?
            .join("fonts");
        options.fontdb_mut().load_system_fonts();
        load_bundled_fonts(&mut options, &fonts)?;
    }
    let tree = usvg::Tree::from_data(&data, &options)?;
    if invalid_image.load(Ordering::Relaxed) {
        return Err("embedded SVG raster is invalid or exceeds image limits".into());
    }
    let size = tree.size();
    let scale = (dimension as f32 / size.width().max(size.height())).min(1.0);
    let width = (size.width() * scale).round().clamp(1.0, dimension as f32) as u32;
    let height = (size.height() * scale).round().clamp(1.0, dimension as f32) as u32;
    // Pixmap is premultiplied in memory; encode_png exports straight RGBA8.
    let mut pixmap = tiny_skia::Pixmap::new(width, height).ok_or("cannot allocate SVG output")?;
    let transform = tiny_skia::Transform::from_scale(
        width as f32 / size.width(),
        height as f32 / size.height(),
    );
    resvg::render(&tree, transform, &mut pixmap.as_mut());
    let png = pixmap.encode_png()?;
    if png.len() > width as usize * height as usize * 4 + 65536 {
        return Err("rendered SVG exceeds bounded PNG output limit".into());
    }
    io::stdout().lock().write_all(&png)?;
    Ok(())
}

fn load_bundled_fonts(options: &mut usvg::Options<'_>, fonts: &Path) -> Result<(), Box<dyn Error>> {
    options.font_family = "Manrope Variable".to_owned();
    let fontdb = options.fontdb_mut();
    fontdb.load_font_file(fonts.join("Manrope-Variable.ttf"))?;
    fontdb.load_font_file(fonts.join("FiraCode-VF.ttf"))?;
    fontdb.set_sans_serif_family("Manrope Variable");
    fontdb.set_serif_family("Manrope Variable");
    fontdb.set_monospace_family("Fira Code");
    let fallback = fontdb
        .query(&usvg::fontdb::Query {
            families: &[usvg::fontdb::Family::Name("Manrope Variable")],
            ..Default::default()
        })
        .ok_or("bundled SVG fallback font could not be loaded")?;
    let select_font = usvg::FontResolver::default_font_selector();
    options.font_resolver.select_font =
        Box::new(move |font, db| select_font(font, db).or(Some(fallback)));
    Ok(())
}

fn validate_resources(xml: &str) -> Result<bool, Box<dyn Error>> {
    let doc = roxmltree::Document::parse_with_options(
        xml,
        roxmltree::ParsingOptions {
            nodes_limit: 100_000,
            ..Default::default()
        },
    )?;
    if doc.root_element().tag_name().name() != "svg" {
        return Err("not an SVG document".into());
    }
    let mut has_text = false;
    for node in doc.descendants().filter(|node| node.is_element()) {
        let tag = node.tag_name().name();
        has_text |= tag == "text";
        if tag.eq_ignore_ascii_case("script") || tag.eq_ignore_ascii_case("foreignObject") {
            return Err("SVG scripts and foreignObject are unsupported".into());
        }
        for attr in node.attributes() {
            let name = attr.name();
            let value = attr.value();
            if name.eq_ignore_ascii_case("base")
                && attr.namespace() == Some("http://www.w3.org/XML/1998/namespace")
            {
                return Err("SVG xml:base is unsupported".into());
            }
            if name.eq_ignore_ascii_case("href") {
                let local = value.trim().starts_with('#');
                let embedded_raster = tag.eq_ignore_ascii_case("image")
                    && [
                        "data:image/png;base64,",
                        "data:image/jpeg;base64,",
                        "data:image/jpg;base64,",
                    ]
                    .iter()
                    .any(|prefix| {
                        value
                            .get(..prefix.len())
                            .is_some_and(|start| start.eq_ignore_ascii_case(prefix))
                    });
                if !embedded_raster && (tag.eq_ignore_ascii_case("image") || !local) {
                    return Err(
                        "external SVG references and nested SVG images are unsupported".into(),
                    );
                }
            }
            if name.eq_ignore_ascii_case("src") && !value.is_empty() {
                return Err("external SVG resources are unsupported".into());
            }
            validate_urls(value)?;
        }
        if tag.eq_ignore_ascii_case("style") {
            for css in node.children().filter_map(|child| child.text()) {
                if contains_ascii_case_insensitive(css, b"@import")
                    || contains_ascii_case_insensitive(css, b"@font-face")
                {
                    return Err("SVG stylesheet imports and embedded fonts are unsupported".into());
                }
                validate_urls(css)?;
            }
        }
    }
    Ok(has_text)
}

// Internal gradients, masks, clips and filters use url(#id). Any other URL is
// rejected before usvg parses the document, rather than silently dropping it.
fn validate_urls(value: &str) -> Result<(), Box<dyn Error>> {
    let mut remaining = value;
    while let Some(start) = remaining
        .as_bytes()
        .windows(4)
        .position(|part| part.eq_ignore_ascii_case(b"url("))
    {
        let after_open = &remaining[start + 4..];
        let end = after_open.find(')').ok_or("invalid SVG url() reference")?;
        let reference = after_open[..end].trim().trim_matches(['\'', '"']).trim();
        if !reference.starts_with('#')
            || reference.len() == 1
            || reference.contains('(')
            || reference.contains(')')
        {
            return Err("external SVG resources are unsupported (only url(#id) is allowed)".into());
        }
        remaining = &after_open[end + 1..];
    }
    Ok(())
}

fn contains_ascii_case_insensitive(value: &str, needle: &[u8]) -> bool {
    value
        .as_bytes()
        .windows(needle.len())
        .any(|part| part.eq_ignore_ascii_case(needle))
}

#[cfg(test)]
mod tests {
    use super::{load_bundled_fonts, validate_resources};
    use resvg::{tiny_skia, usvg};
    use std::path::Path;

    #[test]
    fn renders_default_and_missing_fonts_without_system_fonts() {
        let mut options = usvg::Options::default();
        let fonts = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../../../cc_ui/fonts");
        load_bundled_fonts(&mut options, &fonts).unwrap();
        let tree = usvg::Tree::from_str(
            r#"<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><text x="16" y="48" text-anchor="middle" font-size="48">I</text><text x="48" y="48" text-anchor="middle" font-size="48" font-family="Unavailable Preview Font">I</text></svg>"#,
            &options,
        ).unwrap();
        let mut pixels = tiny_skia::Pixmap::new(64, 64).unwrap();
        resvg::render(
            &tree,
            tiny_skia::Transform::identity(),
            &mut pixels.as_mut(),
        );
        for x in [16, 48] {
            assert!(
                pixels.pixels()[30 * 64 + x - 1]
                    .alpha()
                    .max(pixels.pixels()[30 * 64 + x].alpha())
                    > 64
            );
        }
        assert_eq!(pixels.pixels()[0].alpha(), 0);
    }

    #[test]
    fn allows_internal_gradients_and_relative_geometry() {
        let svg = r##"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 10">
          <defs><linearGradient id="fade"><stop stop-color="#f00"/></linearGradient></defs>
          <rect width="20" height="10" fill="url(#fade)"/>
          <use href="#fade"/>
        </svg>"##;
        assert!(validate_resources(svg).is_ok());
    }

    #[test]
    fn accepts_self_contained_png_and_jpeg_data_references() {
        for mime in ["png", "jpeg"] {
            let svg = format!(r#"<svg><image href="data:image/{mime};base64,AAAA"/></svg>"#);
            assert!(validate_resources(&svg).is_ok(), "{mime}");
        }
    }

    #[test]
    fn rejects_external_resource_paths_urls_and_nested_svg_data() {
        for svg in [
            r#"<svg><image href="../secret.png"/></svg>"#,
            r#"<svg><image href="file:///etc/passwd"/></svg>"#,
            r#"<svg><image href="https://example.com/pixel.png"/></svg>"#,
            r#"<svg><image href="data:image/svg+xml;base64,PHN2Zy8+"/></svg>"#,
            r#"<svg><image href="data:image/webp;base64,AAAA"/></svg>"#,
            r#"<svg><rect fill="url(file:///etc/passwd)"/></svg>"#,
            r#"<svg><style>@import url(https://example.com/style.css)</style></svg>"#,
            r#"<svg xml:base="file:///etc/"><rect/></svg>"#,
            r#"<svg><script>alert('bad')</script></svg>"#,
            r#"<svg><foreignObject><html/></foreignObject></svg>"#,
        ] {
            assert!(validate_resources(svg).is_err(), "{svg}");
        }
    }
}

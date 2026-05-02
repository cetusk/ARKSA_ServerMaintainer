fn main() {
    let config = slint_build::CompilerConfiguration::new()
        .with_style("fluent".to_string());
    slint_build::compile_with_config("ui/main.slint", config)
        .expect("Slint build failed");

    // Phase 0: ship a minimal English-only catalog. JA gets added in Phase 7.
    println!("cargo:rerun-if-changed=ui");
    println!("cargo:rerun-if-changed=i18n");
}

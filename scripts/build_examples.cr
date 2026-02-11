#!/usr/bin/env crystal
# Build Go and Crystal examples, outputting binaries to build/ directory with suffixes.
# Usage: crystal run scripts/build_examples.cr [options]

require "option_parser"
require "file_utils"
require "path"
require "set"

module BuildExamples
  VERSION = "0.1.0"

  # Mapping from module prefixes to vendor directory names, sorted by prefix length descending
  # to ensure longest prefix matches first.
  MODULE_VENDOR_PAIRS = [
    # Specific submodules under x/
    {"github.com/charmbracelet/x/exp/charmtone", "x/exp/charmtone"},
    {"github.com/charmbracelet/x/exp/golden", "x/exp/golden"},
    {"github.com/charmbracelet/x/exp/higherorder", "x/exp/higherorder"},
    {"github.com/charmbracelet/x/exp/maps", "x/exp/maps"},
    {"github.com/charmbracelet/x/exp/open", "x/exp/open"},
    {"github.com/charmbracelet/x/exp/ordered", "x/exp/ordered"},
    {"github.com/charmbracelet/x/exp/slice", "x/exp/slice"},
    {"github.com/charmbracelet/x/exp/strings", "x/exp/strings"},
    {"github.com/charmbracelet/x/exp/teatest", "x/exp/teatest"},
    {"github.com/charmbracelet/x/exp/toner", "x/exp/toner"},
    {"github.com/charmbracelet/x/ansi", "x/ansi"},
    {"github.com/charmbracelet/x/cellbuf", "x/cellbuf"},
    {"github.com/charmbracelet/x/colors", "x/colors"},
    {"github.com/charmbracelet/x/conpty", "x/conpty"},
    {"github.com/charmbracelet/x/editor", "x/editor"},
    {"github.com/charmbracelet/x/errors", "x/errors"},
    {"github.com/charmbracelet/x/etag", "x/etag"},
    {"github.com/charmbracelet/x/gitignore", "x/gitignore"},
    {"github.com/charmbracelet/x/input", "x/input"},
    {"github.com/charmbracelet/x/json", "x/json"},
    {"github.com/charmbracelet/x/mosaic", "x/mosaic"},
    {"github.com/charmbracelet/x/pony", "x/pony"},
    {"github.com/charmbracelet/x/powernap", "x/powernap"},
    {"github.com/charmbracelet/x/sshkey", "x/sshkey"},
    {"github.com/charmbracelet/x/term", "x/term"},
    {"github.com/charmbracelet/x/termios", "x/termios"},
    {"github.com/charmbracelet/x/vcr", "x/vcr"},
    {"github.com/charmbracelet/x/vt", "x/vt"},
    {"github.com/charmbracelet/x/vttest", "x/vttest"},
    {"github.com/charmbracelet/x/wcwidth", "x/wcwidth"},
    {"github.com/charmbracelet/x/windows", "x/windows"},
    {"github.com/charmbracelet/x/xpty", "x/xpty"},
    # Charm land v2 modules
    {"charm.land/bubbles/v2", "bubbles"},
    {"charm.land/bubbletea/v2", "bubbletea"},
    {"charm.land/lipgloss/v2", "lipgloss"},
    # Bubblezone (if needed)
    {"github.com/lrstanley/bubblezone", "bubblezone"},
    # Generic x/ prefix (catch-all for other x submodules)
    {"github.com/charmbracelet/x/", "x"},
  ]

  class Config
    property output_dir = "build"
    property clean = false
    property build_all = false
    property list = false
    property verbose = false
    property target_dirs = [] of String
    property fix_go_mod = true
  end

  def self.run(args)
    config = Config.new

    OptionParser.parse(args) do |parser|
      parser.banner = "Usage: #{PROGRAM_NAME} [options]"

      parser.on("-a", "--all", "Build all Go and Crystal examples") do
        config.build_all = true
      end

      parser.on("-c", "--clean", "Delete all built binaries") do
        config.clean = true
      end

      parser.on("-d DIR", "--dir=DIR", "Build examples in specific directory (relative to examples/)") do |dir|
        config.target_dirs << dir
      end

      parser.on("-l", "--list", "List all example directories with both Go and Crystal") do
        config.list = true
      end

      parser.on("-o DIR", "--output=DIR", "Output directory (default: build/)") do |dir|
        config.output_dir = dir
      end

      parser.on("-v", "--verbose", "Verbose output") do
        config.verbose = true
      end

      parser.on("--no-fix-go-mod", "Skip fixing go.mod replace directives") do
        config.fix_go_mod = false
      end

      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end

      parser.on("--version", "Show version") do
        puts "build_examples #{VERSION}"
        exit
      end

      parser.invalid_option do |flag|
        STDERR.puts "ERROR: #{flag} is not a valid option."
        STDERR.puts parser
        exit 1
      end
    end

    # Ensure output directory exists
    Dir.mkdir_p(config.output_dir) unless Dir.exists?(config.output_dir)

    if config.clean
      clean_binaries(config)
      return
    end

    if config.list
      list_examples(config)
      return
    end

    if config.build_all || !config.target_dirs.empty?
      build_examples(config)
    else
      STDERR.puts "ERROR: No action specified. Use --all, --dir, --clean, or --list."
      exit 1
    end
  end

  def self.clean_binaries(config)
    puts "Cleaning binaries in #{config.output_dir}/" if config.verbose
    Dir.glob("#{config.output_dir}/*-go").each do |path|
      File.delete(path) if File.file?(path)
      puts "Deleted #{path}" if config.verbose
    end
    Dir.glob("#{config.output_dir}/*-cr").each do |path|
      File.delete(path) if File.file?(path)
      puts "Deleted #{path}" if config.verbose
    end
    puts "Cleaned binaries." if config.verbose
  end

  def self.list_examples(config)
    examples = find_example_dirs()
    puts "Found #{examples.size} example directories:"
    examples.each do |dir|
      go_files = Dir.glob("#{dir}/*.go").size
      cr_files = Dir.glob("#{dir}/*.cr").size
      puts "  #{dir} (Go: #{go_files}, Crystal: #{cr_files})"
    end
  end

  def self.find_example_dirs
    example_dirs = [] of String
    # Find directories containing .go files (excluding vendor)
    Dir.glob("examples/**/*.go").each do |go_path|
      dir = File.dirname(go_path)
      example_dirs << dir unless example_dirs.includes?(dir)
    end
    # Also include directories with .cr files but no .go (Crystal-only)
    Dir.glob("examples/**/*.cr").each do |cr_path|
      dir = File.dirname(cr_path)
      unless example_dirs.includes?(dir)
        # Check if there's any .go file in this directory
        if Dir.glob("#{dir}/*.go").empty?
          example_dirs << dir
        end
      end
    end
    example_dirs.sort
  end

  def self.find_go_mod_dir(dir)
    # Walk up from dir to find go.mod file
    current = dir
    while current != "." && current != "/"
      if File.exists?(File.join(current, "go.mod"))
        return current
      end
      current = File.dirname(current)
    end
    nil
  end

  def self.fix_go_mod_file(go_mod_dir, config)
    go_mod_path = File.join(go_mod_dir, "go.mod")
    return unless File.exists?(go_mod_path)

    puts "  Fixing go.mod replace directives in #{go_mod_path}" if config.verbose

    content = File.read(go_mod_path)
    lines = content.lines

    # Collect existing replace directives
    replace_map = {} of String => String
    lines.each do |line|
      # Match replace directive (single line or start of block)
      if line =~ /^\s*replace\s+([^\s]+)\s+=>\s+(.+)$/
        module_name = $1
        replace_path = $2.strip
        replace_map[module_name] = replace_path
      elsif line =~ /^\s*replace\s*\(/
        # Start of replace block - we'll handle by removing all replace lines
        # and rebuilding later
      end
    end

    # Collect all module names mentioned in require statements
    # and direct dependencies (module path version)
    mentioned_modules = Set(String).new
    in_require_block = false
    lines.each do |line|
      stripped = line.strip
      # Skip comments
      next if stripped.starts_with?("//")

      if stripped == "require ("
        in_require_block = true
        next
      elsif stripped == ")"
        in_require_block = false
        next
      end

      # Single-line require
      if line =~ /^\s*require\s+([^\s]+)/
        mentioned_modules << $1
      elsif in_require_block || line =~ /^\s*([^\s]+)\s+v[\d\.]/
        # Inside require block or direct dependency line (module version)
        # Extract module path before version
        if match = line.match(/^\s*([^\s]+)\s+v[\d\.]/)
          mentioned_modules << match[1]
        end
      end
    end

    vendor_root = Path[Dir.current].join("vendor")
    updated = false

    # Track which modules we've already matched to avoid duplicate replaces
    matched_modules = Set(String).new

    # Check each module prefix in our map (longest first)
    MODULE_VENDOR_PAIRS.each do |(module_prefix, vendor_subdir)|
      # Find which mentioned modules match this prefix
      mentioned_modules.each do |module_name|
        next if matched_modules.includes?(module_name)
        # Prefix matching: if prefix ends with '/', treat as prefix, else exact match
        if module_prefix.ends_with?("/")
          next unless module_name.starts_with?(module_prefix)
        else
          next unless module_name == module_prefix
        end

        matched_modules << module_name
        # Check if vendor directory exists
        vendor_path = vendor_root.join(vendor_subdir)
        unless Dir.exists?(vendor_path.to_s)
          puts "  WARN: Vendor directory not found: #{vendor_path}" if config.verbose
          next
        end

        # Compute relative path from go_mod_dir to vendor_path
        rel_path = Path[vendor_path].expand.relative_to(Path[go_mod_dir].expand).to_s

        # Update or add replace directive
        if replace_map[module_name]? != rel_path
          puts "    Adding replace #{module_name} => #{rel_path}" if config.verbose
          replace_map[module_name] = rel_path
          updated = true
        end
      end
    end

    # If no updates needed, return
    return unless updated

    # Rebuild go.mod content, preserving all non-replace lines
    # and adding a replace block after the go line
    new_lines = [] of String
    in_replace_block = false
    replace_added = false

    lines.each do |line|
      # Skip lines that are part of replace directives
      if line =~ /^\s*replace\s/
        # If this is start of replace block, skip and mark we're in block
        if line =~ /^\s*replace\s*\(/
          in_replace_block = true
        end
        next
      elsif in_replace_block
        # Skip until we find closing parenthesis
        if line.strip == ")"
          in_replace_block = false
        end
        next
      else
        new_lines << line
      end

      # Insert replace block after go version line
      if !replace_added && line =~ /^\s*go\s+\d+/
        new_lines << ""
        new_lines << "replace ("
        replace_map.each do |module_name, path|
          new_lines << "  #{module_name} => #{path}"
        end
        new_lines << ")"
        new_lines << ""
        replace_added = true
      end
    end

    # If we didn't find go line (shouldn't happen), prepend replace block
    unless replace_added
      new_lines.unshift("", "replace (")
      replace_map.each do |module_name, path|
        new_lines.insert(1, "  #{module_name} => #{path}")
      end
      new_lines.insert(1 + replace_map.size, ")")
      new_lines.insert(2 + replace_map.size, "")
    end

    File.write(go_mod_path, new_lines.join("\n"))
    puts "  Updated #{go_mod_path}" if config.verbose

    # Run go mod tidy to update go.sum
    if updated
      puts "  Running go mod tidy" if config.verbose
      Process.run("go", ["mod", "tidy"], chdir: go_mod_dir, output: config.verbose ? Process::Redirect::Inherit : Process::Redirect::Close, error: config.verbose ? Process::Redirect::Inherit : Process::Redirect::Close)
    end
  end

  def self.build_examples(config)
    examples = find_example_dirs()
    # Filter if target_dirs specified
    unless config.target_dirs.empty?
      examples = examples.select do |dir|
        config.target_dirs.any? { |target| dir.includes?(target) }
      end
    end

    puts "Building #{examples.size} example directories..." if config.verbose

    examples.each do |dir|
      build_example_dir(dir, config)
    end

    puts "Done." if config.verbose
  end

  def self.build_example_dir(dir, config)
    # Determine base name for output binary
    # Convert path like examples/bubbletea/tabs to bubbletea-tabs
    rel_path = dir.sub(/^examples\//, "").gsub("/", "-")

    go_files = Dir.glob("#{dir}/*.go")
    cr_files = Dir.glob("#{dir}/*.cr")

    if go_files.any?
      build_go_example(dir, rel_path, go_files, config)
    end

    if cr_files.any?
      build_crystal_example(dir, rel_path, cr_files, config)
    end
  end

  def self.build_go_example(dir, rel_path, go_files, config)
    go_mod_dir = find_go_mod_dir(dir)
    unless go_mod_dir
      puts "WARN: No go.mod found for #{dir}, skipping Go build" if config.verbose
      return
    end

    # Fix go.mod replace directives if enabled
    if config.fix_go_mod
      fix_go_mod_file(go_mod_dir, config)
    end

    # Determine main.go file (prefer main.go, else first .go)
    main_go = go_files.find { |f| f.ends_with?("main.go") } || go_files.first
    # Relative path from go_mod_dir to main_go
    rel_to_mod = Path[main_go].relative_to(Path[go_mod_dir]).to_s

    output_name = "#{rel_path}-go"
    output_path = File.expand_path(File.join(config.output_dir, output_name))

    puts "Building Go: #{dir} -> #{output_name}" if config.verbose

    # Change to go_mod_dir and run go build
    cmd = ["go", "build", "-o", output_path, "./#{rel_to_mod}"]
    if config.verbose
      puts "  cd #{go_mod_dir}"
      puts "  #{cmd.join(" ")}"
    end

    status = nil
    if config.verbose
      status = Process.run(
        cmd[0],
        cmd[1..],
        chdir: go_mod_dir,
        output: Process::Redirect::Inherit,
        error: Process::Redirect::Inherit
      )
    else
      output = Process::Redirect::Close
      error = IO::Memory.new
      status = Process.run(
        cmd[0],
        cmd[1..],
        chdir: go_mod_dir,
        output: output,
        error: error
      )
      unless status.success?
        puts "ERROR: Go build failed for #{dir}"
        err_str = error.to_s
        puts err_str if !err_str.empty?
      end
    end

    if status && !status.success?
      # Error already printed
    end
  end

  def self.build_crystal_example(dir, rel_path, cr_files, config)
    # Determine main.cr file (prefer main.cr, else first .cr)
    main_cr = cr_files.find { |f| f.ends_with?("main.cr") } || cr_files.first

    output_name = "#{rel_path}-cr"
    output_path = File.join(config.output_dir, output_name)

    puts "Building Crystal: #{dir} -> #{output_name}" if config.verbose

    # Use shared crystal cache
    env = {"CRYSTAL_CACHE_DIR" => File.join(Dir.current, ".crystal-cache")}
    cmd = ["crystal", "build", "--no-color", "--release", "-Dpreview_mt", "-Dexecution_context", "-o", output_path, main_cr]

    if config.verbose
      puts "  #{cmd.join(" ")}"
    end

    output = config.verbose ? Process::Redirect::Inherit : Process::Redirect::Close
    error = config.verbose ? Process::Redirect::Inherit : Process::Redirect::Close
    status = Process.run(
      cmd[0],
      cmd[1..],
      env: env,
      output: output,
      error: error
    )

    unless status.success?
      puts "ERROR: Crystal build failed for #{dir}" unless config.verbose
    end
  end
end

BuildExamples.run(ARGV)

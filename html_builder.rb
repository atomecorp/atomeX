#!/usr/bin/env ruby
require 'optparse'
require 'nokogiri'
require 'fileutils'

# HtmlBuilder class responsible for merging HTML files and copying static assets
class HtmlBuilder
  def initialize(options = {})
    # Initialize paths and directories
    @base_path     = options[:base] || 'html_sources/index.html'
    @target_paths  = options[:targets] || ['html_sources/index_opal.html', 'html_sources/index_wasm.html']
    @output_dir    = options[:output_dir] || 'build'
    @create_symlinks = options[:symlink] || false

    # Create necessary build directories
    create_build_directories
  end

  # Main method to build all HTML files
  def build_all
    # Read and parse the base HTML file
    base_content = File.read(@base_path)
    base_doc = parse_html(base_content)

    # Process each target file
    @target_paths.each do |target_path|
      process_target_file(base_doc, target_path)
    end

    # Copy static assets after HTML processing
    copy_static_assets
  end

  private

  # Create all necessary build directories
  def create_build_directories
    FileUtils.mkdir_p(File.join(@output_dir, 'opal'))
    FileUtils.mkdir_p(File.join(@output_dir, 'wasm'))
    puts "Created build directories in '#{@output_dir}'"
  end

  # Process a single target file and merge it with the base
  def process_target_file(base_doc, target_path)
    target_name = File.basename(target_path)
    output_path = File.join(@output_dir, target_name)

    puts "Processing #{target_path} to create #{output_path}..."

    # Read and parse the target HTML file
    target_content = File.read(target_path)
    target_doc = parse_html(target_content)

    # Merge the documents
    merged_doc = merge_documents(base_doc.dup, target_doc)

    # Write the formatted output to file
    write_html_file(merged_doc, output_path)

    # Create symlink if requested
    create_symlink(output_path) if @create_symlinks

    puts "#{output_path} was successfully created."
  end

  # Write HTML document to file with proper formatting
  def write_html_file(doc, output_path)
    File.write(output_path, doc.to_html(
      save_with: Nokogiri::XML::Node::SaveOptions::FORMAT |
        Nokogiri::XML::Node::SaveOptions::AS_HTML
    ))
  end

  # Create symlink if the option is enabled
  def create_symlink(output_path)
    symlink_name = "#{output_path}.link"
    FileUtils.ln_sf(output_path, symlink_name)
    puts "Created symlink: #{symlink_name} -> #{output_path}"
  end

  # Parse HTML content safely
  def parse_html(content)
    begin
      # Use parse options to preserve whitespaces
      Nokogiri::HTML(content, nil, 'UTF-8')
    rescue => e
      puts "Error while parsing HTML: #{e.message}"
      # Return empty HTML document as fallback
      Nokogiri::HTML("<!DOCTYPE html><html><head></head><body></body></html>")
    end
  end

  # Merge two HTML documents into one
  def merge_documents(base_doc, target_doc)
    # Create a new document for the merged content
    merged_doc = Nokogiri::HTML("<!DOCTYPE html><html><head></head><body></body></html>")

    # Get references to head and body elements
    base_head = base_doc.at_css('head')
    target_head = target_doc.at_css('head')
    base_body = base_doc.at_css('body')
    target_body = target_doc.at_css('body')
    merged_head = merged_doc.at_css('head')
    merged_body = merged_doc.at_css('body')

    # Merge head elements
    merge_head_elements(base_head, target_head, merged_head)

    # Merge body elements
    merge_body_elements(base_body, target_body, merged_body)

    # Merge elements after body
    merge_after_body_elements(base_doc, target_doc, merged_doc)

    # Format the final document
    format_document(merged_doc)
  end

  # Copy static assets from app and sources folders
  def copy_static_assets
    copy_directory('app', @output_dir)
    copy_directory('sources', @output_dir)
  end

  # Helper method to copy a directory if it exists
  def copy_directory(dir_name, destination)
    if Dir.exist?(dir_name)
      begin
        FileUtils.cp_r("./#{dir_name}", "./#{destination}/")
        puts "Static #{dir_name} folder copied from './#{dir_name}' to '#{destination}/'"
      rescue => e
        puts "Error while copying #{dir_name} folder: #{e.message}"
      end
    else
      puts "'#{dir_name}' folder does not exist, skipping copy."
    end
  end

  # Merge body elements from base and target documents
  def merge_body_elements(base_body, target_body, merged_body)
    if target_body && !is_body_empty?(target_body)
      # If target body has content, use it
      merged_body.inner_html = target_body.inner_html
    elsif base_body
      # Otherwise, use base body content
      merged_body.inner_html = base_body.inner_html
    end
  end

  # Merge head elements from base and target documents
  def merge_head_elements(base_head, target_head, merged_head)
    return unless base_head && merged_head

    # Copy all base head elements
    copy_head_elements(base_head, merged_head)

    # Add target head elements, checking for duplicates
    add_target_head_elements(target_head, merged_head) if target_head
  end

  # Copy head elements from source to destination
  def copy_head_elements(source_head, dest_head)
    source_head.children.each do |child|
      next unless non_empty?(child)
      dest_head.add_child(child.dup)
    end
  end

  # Add target head elements, checking for duplicates
  def add_target_head_elements(target_head, merged_head)
    target_head.children.each do |child|
      next unless non_empty?(child)

      if should_check_for_duplicates?(child)
        # Only add if the element doesn't already exist
        merged_head.add_child(child.dup) unless element_exists?(merged_head, child)
      else
        # Always add script tags and other elements
        merged_head.add_child(child.dup)
      end
    end
  end

  # Determine if we should check for duplicates for this element type
  def should_check_for_duplicates?(element)
    return false unless element.element?
    return false if element.name == 'script'

    # Check duplicates for title, meta with name, or link with href
    (element.name == 'title') ||
      (element.name == 'meta' && element['name']) ||
      (element.name == 'link' && element['href'])
  end

  # Check if a body node is empty (contains only whitespace)
  def is_body_empty?(body_node)
    return true unless body_node
    body_node.children.all? { |c| c.text? && c.text.strip.empty? }
  end

  # Merge HTML content that appears after the closing body tag
  def merge_after_body_elements(base_doc, target_doc, merged_doc)
    base_after_body_html = extract_after_body_html(base_doc)
    target_after_body_html = extract_after_body_html(target_doc)

    # Prefer target after-body content, fall back to base if empty
    after_body_html = target_after_body_html.empty? ? base_after_body_html : target_after_body_html

    # Add after-body content if it exists
    add_after_body_content(merged_doc, after_body_html) unless after_body_html.empty?
  end

  # Add content after the body tag
  def add_after_body_content(doc, after_body_html)
    body_node = doc.at_css('body')
    next_node = body_node.next_sibling

    if next_node
      next_node.add_previous_sibling(Nokogiri::HTML.fragment(after_body_html))
    else
      html_node = doc.at_css('html')
      html_node.add_child(Nokogiri::HTML.fragment(after_body_html))
    end
  end

  # Extract HTML content that appears after the closing body tag
  def extract_after_body_html(doc)
    html_content = doc.to_html
    if html_content =~ /<\/body>(.*?)<\/html>/im
      return $1.to_s
    end
    return ""
  end

  # Format the document with proper DOCTYPE and essential elements
  def format_document(doc)
    # Reset and create proper DOCTYPE
    doc.internal_subset&.remove
    doc.create_internal_subset('html', nil, nil)

    # Ensure html element exists
    ensure_element_exists(doc, 'html', nil) do |html_node|
      doc.root = html_node
    end

    # Ensure head element exists
    ensure_element_exists(doc, 'head', 'html')

    # Ensure body element exists
    ensure_element_exists(doc, 'body', 'html')

    # Add charset meta if not present
    add_charset_meta(doc)

    # Add title if not present
    add_title_if_missing(doc)

    return doc
  end

  # Ensure an element exists, create it if missing
  def ensure_element_exists(doc, element_name, parent_selector)
    unless doc.at_css(element_name)
      new_node = Nokogiri::XML::Node.new(element_name, doc)
      if parent_selector
        parent = doc.at_css(parent_selector)
        parent.add_child(new_node)
      else
        yield(new_node) if block_given?
      end
    end
  end

  # Add charset meta tag if missing
  def add_charset_meta(doc)
    head = doc.at_css('head')
    unless head.at_css('meta[charset]')
      meta = Nokogiri::XML::Node.new('meta', doc)
      meta['charset'] = 'UTF-8'
      head.prepend_child(meta)
    end
  end

  # Add title if missing
  def add_title_if_missing(doc)
    head = doc.at_css('head')
    unless head.at_css('title')
      title = Nokogiri::XML::Node.new('title', doc)
      title.content = '©atome 2025'
      head.add_child(title)
    end
  end

  # Check if a node is not just whitespace
  def non_empty?(node)
    !(node.text? && node.text.strip.empty?)
  end

  # Check if a similar element already exists in the merged head
  def element_exists?(merged_head, child)
    return false unless child.element?

    case child.name
    when 'link'
      check_link_exists(merged_head, child)
    when 'meta'
      check_meta_exists(merged_head, child)
    when 'title'
      update_existing_title(merged_head, child)
    else
      false
    end
  end

  # Check if a link element with the same href exists
  def check_link_exists(merged_head, child)
    return false unless child['href']
    merged_head.css('link').any? { |l| l['href'] == child['href'] }
  end

  # Check if a meta element with the same name exists
  def check_meta_exists(merged_head, child)
    return false unless child['name']
    merged_head.css('meta').any? { |m| m['name'] == child['name'] }
  end

  # Update existing title or return false if not exists
  def update_existing_title(merged_head, child)
    existing_title = merged_head.at_css('title')
    if existing_title
      existing_title.content = child.content
      true
    else
      false
    end
  end
end

# --- Main execution block ---
if __FILE__ == $0
  options = {}

  # Parse command line options
  OptionParser.new do |opts|
    opts.banner = "Usage: ruby html_builder.rb [options]"

    opts.on("-b", "--base PATH", "Path to base HTML file (default: html_sources/index.html)") do |b|
      options[:base] = b
    end

    opts.on("-t", "--targets x,y,z", Array, "List of target HTML files separated by commas (default: html_sources/index_opal.html, html_sources/index_wasm.html)") do |t|
      options[:targets] = t
    end

    opts.on("-o", "--output DIR", "Output directory (default: build)") do |o|
      options[:output_dir] = o
    end

    opts.on("--symlink", "Create symlinks for HTML files") do
      options[:symlink] = true
    end

    opts.on("-h", "--help", "Show help") do
      puts opts
      exit
    end
  end.parse!

  begin
    # Create builder instance and run the process
    builder = HtmlBuilder.new(options)
    builder.build_all

    puts "All build scripts executed successfully."
    puts "To start the server with hot-reloading, use: ruby builder.rb --serve"
  rescue => e
    puts "Error while executing: #{e.message}"
    puts e.backtrace
    exit 1
  end
end
#!/usr/bin/env ruby
# ruby_builder.rb - Script intelligent pour générer index_opal.html et index_wasm.html

require 'nokogiri'
require 'fileutils'

class HtmlBuilder
  def initialize(base_path, target_paths, output_dir = 'build')
    @base_path = base_path
    @target_paths = target_paths
    @output_dir = output_dir

    # Créer le dossier build s'il n'existe pas
    Dir.mkdir(@output_dir) unless Dir.exist?(@output_dir)
  end

  def build_all
    # Lire et parser le fichier de base
    base_content = File.read(@base_path)
    base_doc = parse_html(base_content)

    @target_paths.each do |target_path|
      target_name = File.basename(target_path)
      output_path = File.join(@output_dir, target_name)

      puts "Traitement de #{target_path} pour créer #{output_path}..."

      # Lire et parser le fichier cible
      target_content = File.read(target_path)
      target_doc = parse_html(target_content)

      # Fusionner les documents
      merged_doc = merge_documents(base_doc, target_doc)

      # Écrire le résultat formaté dans le fichier de sortie
      File.write(output_path, merged_doc.to_html)
      puts "#{output_path} a été créé avec succès."
    end
  end

  private

  def parse_html(content)
    # Utiliser Nokogiri pour un parsing robuste du HTML
    begin
      Nokogiri::HTML(content) { |config| config.noblanks }
    rescue => e
      puts "Erreur lors du parsing HTML: #{e.message}"
      Nokogiri::HTML("<!DOCTYPE html><html><head></head><body></body></html>")
    end
  end

  def merge_documents(base_doc, target_doc)
    # Créer un nouveau document pour le résultat
    merged_doc = Nokogiri::HTML("<!DOCTYPE html><html><head></head><body></body></html>")

    # Obtenir les nœuds importants
    base_head = base_doc.at_css('head')
    target_head = target_doc.at_css('head')
    base_body = base_doc.at_css('body')
    target_body = target_doc.at_css('body')
    merged_head = merged_doc.at_css('head')
    merged_body = merged_doc.at_css('body')

    # 1. Fusionner les éléments de head
    merge_head_elements(base_head, target_head, merged_head)

    # 2. Fusionner les éléments du body
    merge_body_elements(base_body, target_body, merged_body)

    # 3. Capturer et fusionner les scripts qui sont après le body (si présents)
    merge_after_body_elements(base_doc, target_doc, merged_doc)

    # Formatage final
    format_document(merged_doc)
  end

  def merge_head_elements(base_head, target_head, merged_head)
    return unless base_head && merged_head

    # Copier tous les éléments de la tête de base
    base_head.children.each do |child|
      next if child.text? && child.text.strip.empty?
      merged_head.add_child(child.dup)
    end

    # Ajouter les éléments de la tête cible qui n'existent pas déjà dans le résultat
    if target_head
      target_head.children.each do |child|
        next if child.text? && child.text.strip.empty?

        # Vérifier si un élément similaire existe déjà
        exists = false

        if child.element?
          # Pour les éléments comme script, link, meta, etc.
          if child.name == 'script' && child['src']
            # Pour les scripts avec src, comparer les attributs src
            exists = merged_head.css('script').any? { |s| s['src'] && s['src'] == child['src'] }
          elsif child.name == 'link' && child['href']
            # Pour les liens, comparer les attributs href
            exists = merged_head.css('link').any? { |l| l['href'] && l['href'] == child['href'] }
          elsif child.name == 'meta' && child['name']
            # Pour les meta tags, comparer les attributs name
            exists = merged_head.css('meta').any? { |m| m['name'] && m['name'] == child['name'] }
          elsif child.name == 'title'
            # Pour le titre, remplacer celui existant
            title = merged_head.at_css('title')
            if title
              title.content = child.content
              exists = true
            end
          end
        end

        # Ajouter l'élément s'il n'existe pas déjà
        merged_head.add_child(child.dup) unless exists
      end
    end
  end

  def merge_body_elements(base_body, target_body, merged_body)
    return unless merged_body

    # On privilégie le contenu du body cible s'il existe et n'est pas vide
    if target_body && !target_body.children.empty? && !is_body_empty?(target_body)
      target_body.children.each do |child|
        next if child.text? && child.text.strip.empty?
        merged_body.add_child(child.dup)
      end
    elsif base_body
      # Sinon on utilise le contenu du body de base
      base_body.children.each do |child|
        next if child.text? && child.text.strip.empty?
        merged_body.add_child(child.dup)
      end
    end
  end

  def is_body_empty?(body_node)
    return true unless body_node
    # Vérifier si le body ne contient que des espaces blancs
    body_node.children.all? { |c| c.text? && c.text.strip.empty? }
  end

  def merge_after_body_elements(base_doc, target_doc, merged_doc)
    # Trouver tous les éléments qui sont après la balise body fermante
    base_after_body = find_after_body_elements(base_doc)
    target_after_body = find_after_body_elements(target_doc)

    # Préférer les éléments de la cible, sinon utiliser ceux de la base
    after_body_elements = target_after_body.empty? ? base_after_body : target_after_body

    # Ajouter ces éléments après le body du document fusionné
    after_body_elements.each do |elem|
      merged_doc.root.add_child(elem.dup)
    end
  end

  def find_after_body_elements(doc)
    elements = []

    # Cette approche est plus complexe car Nokogiri normalise le HTML
    # Nous utilisons le HTML original pour trouver les éléments après </body>
    if doc.to_html =~ /<\/body>(.*?)<\/html>/im
      after_body_html = $1.to_s.strip
      unless after_body_html.empty?
        # Créer un fragment avec ce contenu pour le manipuler avec Nokogiri
        fragment = Nokogiri::HTML.fragment(after_body_html)
        elements = fragment.children
      end
    end

    elements
  end

  def format_document(doc)
    # Assurer que le doctype est correct
    doc.internal_subset&.remove
    doc.create_internal_subset('html', nil, nil)

    # Assurer que les balises essentielles sont présentes
    unless doc.at_css('html')
      root = Nokogiri::XML::Node.new('html', doc)
      doc.root = root
    end

    unless doc.at_css('head')
      head = Nokogiri::XML::Node.new('head', doc)
      doc.root.add_child(head)
    end

    unless doc.at_css('body')
      body = Nokogiri::XML::Node.new('body', doc)
      doc.root.add_child(body)
    end

    # Ajouter charset et title s'ils n'existent pas
    head = doc.at_css('head')

    unless head.at_css('meta[charset]')
      meta = Nokogiri::XML::Node.new('meta', doc)
      meta['charset'] = 'UTF-8'
      head.prepend_child(meta)
    end

    unless head.at_css('title')
      title = Nokogiri::XML::Node.new('title', doc)
      title.content = '©atome 2025'
      head.add_child(title)
    end

    doc
  end
end

# Exécution du script
if __FILE__ == $0
  base_path = 'sources/index.html'
  target_paths = ['sources/index_opal.html', 'sources/index_wasm.html']
  output_dir = 'build'

  begin
    builder = HtmlBuilder.new(base_path, target_paths, output_dir)
    builder.build_all
  rescue => e
    puts "Erreur lors de l'exécution: #{e.message}"
    puts e.backtrace
  end
end

# now copy the app folder

# Créer le dossier build s'il n'existe pas
FileUtils.mkdir_p('./build')

# Copier le dossier app vers build
FileUtils.cp_r('./app', './build/')
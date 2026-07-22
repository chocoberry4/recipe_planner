require 'rails_helper'

RSpec.describe JsonLdRecipeExtractor do
  def html_with_json_ld(payload)
    <<~HTML
      <html><head>
        <script type="application/ld+json">#{payload.to_json}</script>
      </head><body></body></html>
    HTML
  end

  it "extracts title, description, ingredients, and plain-string instructions" do
    html = html_with_json_ld(
      "@context" => "https://schema.org",
      "@type" => "Recipe",
      "name" => "Tacos",
      "description" => "Weeknight tacos",
      "recipeIngredient" => [ "2 eggs", "1 cup flour" ],
      "recipeInstructions" => [ "Whisk the eggs.", "Add the flour." ]
    )

    result = described_class.extract(html)

    expect(result.title).to eq("Tacos")
    expect(result.description).to eq("Weeknight tacos")
    expect(result.ingredient_lines).to eq([ "2 eggs", "1 cup flour" ])
    expect(result.instructions.map(&:text)).to eq([ "Whisk the eggs.", "Add the flour." ])
    expect(result.instructions.map(&:group_name)).to eq([ nil, nil ])
  end

  it "extracts HowToStep hashes" do
    html = html_with_json_ld(
      "@type" => "Recipe",
      "name" => "Tacos",
      "recipeIngredient" => [],
      "recipeInstructions" => [
        { "@type" => "HowToStep", "text" => "Whisk the eggs." },
        { "@type" => "HowToStep", "text" => "Add the flour." }
      ]
    )

    result = described_class.extract(html)

    expect(result.instructions.map(&:text)).to eq([ "Whisk the eggs.", "Add the flour." ])
  end

  it "extracts HowToSection groups and tags their steps with the section name" do
    html = html_with_json_ld(
      "@type" => "Recipe",
      "name" => "Tacos",
      "recipeIngredient" => [],
      "recipeInstructions" => [
        {
          "@type" => "HowToSection",
          "name" => "Marinade",
          "itemListElement" => [
            { "@type" => "HowToStep", "text" => "Whisk 2 tbsp soy sauce with garlic." },
            { "@type" => "HowToStep", "text" => "Add the chicken and toss." }
          ]
        },
        { "@type" => "HowToStep", "text" => "Preheat the grill." }
      ]
    )

    result = described_class.extract(html)

    expect(result.instructions.map { |i| [ i.text, i.group_name ] }).to eq(
      [
        [ "Whisk 2 tbsp soy sauce with garlic.", "Marinade" ],
        [ "Add the chicken and toss.", "Marinade" ],
        [ "Preheat the grill.", nil ]
      ]
    )
  end

  it "extracts a HowToStep's own image, in either string or ImageObject form" do
    html = html_with_json_ld(
      "@type" => "Recipe",
      "name" => "Tacos",
      "recipeIngredient" => [],
      "recipeInstructions" => [
        { "@type" => "HowToStep", "text" => "Whisk the eggs.", "image" => "https://example.com/step1.jpg" },
        { "@type" => "HowToStep", "text" => "Add the flour.", "image" => { "@type" => "ImageObject", "url" => "https://example.com/step2.jpg" } },
        { "@type" => "HowToStep", "text" => "Serve." }
      ]
    )

    result = described_class.extract(html)

    expect(result.instructions.map(&:image_url)).to eq(
      [ "https://example.com/step1.jpg", "https://example.com/step2.jpg", nil ]
    )
  end

  it "extracts step images for steps nested inside a HowToSection" do
    html = html_with_json_ld(
      "@type" => "Recipe",
      "name" => "Tacos",
      "recipeIngredient" => [],
      "recipeInstructions" => [
        {
          "@type" => "HowToSection",
          "name" => "Marinade",
          "itemListElement" => [
            { "@type" => "HowToStep", "text" => "Whisk soy sauce with garlic.", "image" => "https://example.com/marinade.jpg" }
          ]
        }
      ]
    )

    result = described_class.extract(html)

    expect(result.instructions.first.image_url).to eq("https://example.com/marinade.jpg")
  end

  it "unwraps an @graph array to find the Recipe node" do
    html = html_with_json_ld(
      "@context" => "https://schema.org",
      "@graph" => [
        { "@type" => "WebPage", "name" => "Homepage" },
        {
          "@type" => "Recipe",
          "name" => "Tacos",
          "recipeIngredient" => [ "2 eggs" ],
          "recipeInstructions" => [ "Whisk the eggs." ]
        }
      ]
    )

    result = described_class.extract(html)

    expect(result.title).to eq("Tacos")
    expect(result.ingredient_lines).to eq([ "2 eggs" ])
  end

  it "handles recipeInstructions given as a single newline-separated string" do
    html = html_with_json_ld(
      "@type" => "Recipe",
      "name" => "Tacos",
      "recipeIngredient" => [],
      "recipeInstructions" => "Whisk the eggs.\nAdd the flour.\n"
    )

    result = described_class.extract(html)

    expect(result.instructions.map(&:text)).to eq([ "Whisk the eggs.", "Add the flour." ])
  end

  it "decodes raw HTML entities left undecoded in JSON-LD text fields" do
    html = html_with_json_ld(
      "@type" => "Recipe",
      "name" => "Tacos",
      "description" => "you&#39;ll love these",
      "recipeIngredient" => [ "2 eggs&nbsp;(large)" ],
      "recipeInstructions" => [
        { "@type" => "HowToStep", "text" => "Cook chicken:&nbsp;heat the pan." }
      ]
    )

    result = described_class.extract(html)

    expect(result.description).to eq("you'll love these")
    expect(result.ingredient_lines).to eq([ "2 eggs (large)" ])
    expect(result.instructions.map(&:text)).to eq([ "Cook chicken: heat the pan." ])
  end

  it "squishes whitespace left behind after decoding entities" do
    html = html_with_json_ld(
      "@type" => "Recipe",
      "name" => "Tacos",
      "recipeIngredient" => [],
      "recipeInstructions" => [ "  Whisk&nbsp;&nbsp;the eggs.  " ]
    )

    result = described_class.extract(html)

    expect(result.instructions.map(&:text)).to eq([ "Whisk the eggs." ])
  end

  it "returns nil when no Recipe node is present" do
    html = html_with_json_ld("@type" => "WebPage", "name" => "Homepage")

    expect(described_class.extract(html)).to be_nil
  end

  it "returns nil when there is no JSON-LD at all" do
    expect(described_class.extract("<html><body><p>No structured data here.</p></body></html>")).to be_nil
  end

  it "skips malformed JSON-LD and still finds a valid script tag" do
    html = <<~HTML
      <html><head>
        <script type="application/ld+json">{ not valid json </script>
        <script type="application/ld+json">#{ { "@type" => "Recipe", "name" => "Tacos" }.to_json }</script>
      </head></html>
    HTML

    result = described_class.extract(html)

    expect(result.title).to eq("Tacos")
  end
end

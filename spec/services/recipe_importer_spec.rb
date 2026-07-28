require 'rails_helper'

RSpec.describe RecipeImporter do
  describe ".from_url" do
    def html_with_json_ld(payload)
      <<~HTML
        <html><head>
          <script type="application/ld+json">#{payload.to_json}</script>
        </head></html>
      HTML
    end

    it "fetches, extracts, and persists a recipe, running the autosorter" do
      user = create(:user)
      html = html_with_json_ld(
        "@type" => "Recipe",
        "name" => "Tacos",
        "description" => "Weeknight tacos",
        "recipeIngredient" => [ "2 eggs", "1 cup flour" ],
        "recipeInstructions" => [
          {
            "@type" => "HowToSection",
            "name" => "Filling",
            "itemListElement" => [
              { "@type" => "HowToStep", "text" => "Whisk the eggs." }
            ]
          },
          { "@type" => "HowToStep", "text" => "Add the flour and stir." }
        ]
      )
      allow(described_class).to receive(:fetch_html).and_return(html)

      result = described_class.from_url("https://example.com/tacos", user: user)

      expect(result).to be_ok
      recipe = result.recipe
      expect(recipe.title).to eq("Tacos")
      expect(recipe.description).to eq("Weeknight tacos")
      expect(recipe.source_url).to eq("https://example.com/tacos")
      expect(recipe.user).to eq(user)
      expect(recipe.recipe_ingredients.map { |ri| [ ri.quantity, ri.unit, ri.ingredient.name ] })
        .to contain_exactly([ 2.0, nil, "eggs" ], [ 1.0, "cup", "flour" ])
      expect(recipe.instructions.count).to eq(2)

      filling_group = recipe.recipe_ingredient_groups.find_by(name: "Filling")
      expect(filling_group).to be_present
      expect(recipe.instructions.find_by(description: "Whisk the eggs.").recipe_ingredient_group).to eq(filling_group)

      # RecipeAutosorter ran: the "eggs" step should have matched the eggs ingredient.
      egg_step = recipe.instructions.find_by(description: "Whisk the eggs.")
      expect(egg_step.recipe_ingredients.map { |ri| ri.ingredient.name }).to include("eggs")
    end

    it "persists each step's own image when the source's JSON-LD provides one" do
      user = create(:user)
      html = html_with_json_ld(
        "@type" => "Recipe",
        "name" => "Tacos",
        "recipeIngredient" => [ "2 eggs" ],
        "recipeInstructions" => [
          { "@type" => "HowToStep", "text" => "Whisk the eggs.", "image" => "https://example.com/step1.jpg" },
          { "@type" => "HowToStep", "text" => "Serve." }
        ]
      )
      allow(described_class).to receive(:fetch_html).and_return(html)

      result = described_class.from_url("https://example.com/tacos", user: user)

      expect(result).to be_ok
      expect(result.recipe.instructions.find_by(description: "Whisk the eggs.").image_url).to eq("https://example.com/step1.jpg")
      expect(result.recipe.instructions.find_by(description: "Serve.").image_url).to be_nil
    end

    it "persists duration_minutes parsed from the source's totalTime" do
      user = create(:user)
      html = html_with_json_ld(
        "@type" => "Recipe",
        "name" => "Tacos",
        "recipeIngredient" => [ "2 eggs" ],
        "recipeInstructions" => [ { "@type" => "HowToStep", "text" => "Whisk the eggs." } ],
        "totalTime" => "PT45M"
      )
      allow(described_class).to receive(:fetch_html).and_return(html)

      result = described_class.from_url("https://example.com/tacos", user: user)

      expect(result).to be_ok
      expect(result.recipe.duration_minutes).to eq(45)
    end

    it "strips checkbox glyphs baked directly into a site's JSON-LD recipeIngredient text" do
      user = create(:user)
      html = html_with_json_ld(
        "@type" => "Recipe",
        "name" => "Noodles",
        "description" => "Weeknight noodles",
        "recipeIngredient" => [ "▢1 garlic clove, minced" ],
        "recipeInstructions" => [ { "@type" => "HowToStep", "text" => "Add garlic." } ]
      )
      allow(described_class).to receive(:fetch_html).and_return(html)

      result = described_class.from_url("https://example.com/noodles", user: user)

      expect(result).to be_ok
      ri = result.recipe.recipe_ingredients.sole
      expect(ri.ingredient.name).to eq("garlic")
      expect(ri.unit).to eq("clove")
    end

    it "returns a no_structured_data failure and persists nothing when the page has no JSON-LD" do
      user = create(:user)
      allow(described_class).to receive(:fetch_html).and_return("<html><body>no data here</body></html>")

      expect do
        result = described_class.from_url("https://example.com/no-recipe", user: user)
        expect(result).not_to be_ok
        expect(result.reason).to eq(:no_structured_data)
      end.not_to change(Recipe, :count)
    end

    it "returns an invalid_url failure without attempting a network request for a private-network URL" do
      user = create(:user)
      expect(Net::HTTP).not_to receive(:start)

      result = described_class.from_url("http://127.0.0.1/recipe", user: user)

      expect(result).not_to be_ok
      expect(result.reason).to eq(:invalid_url)
    end
  end

  describe ".image_candidates_for" do
    def html_with_images(json_ld_images:, body:)
      <<~HTML
        <html><head>
          <script type="application/ld+json">#{{ "@type" => "Recipe", "name" => "Tacos", "image" => json_ld_images }.to_json}</script>
        </head><body>#{body}</body></html>
      HTML
    end

    it "leads with JSON-LD images, then every other <img> found on the page" do
      html = html_with_images(
        json_ld_images: [ "https://example.com/hero.jpg" ],
        body: '<img src="https://example.com/gallery-1.jpg"><img src="/gallery-2.jpg">'
      )
      allow(described_class).to receive(:fetch_html).and_return(html)

      urls = described_class.image_candidates_for("https://example.com/tacos")

      expect(urls).to eq([
        "https://example.com/hero.jpg",
        "https://example.com/gallery-1.jpg",
        "https://example.com/gallery-2.jpg"
      ])
    end

    it "resolves a page-relative <img src> against the source page's URL" do
      html = html_with_images(json_ld_images: [], body: '<img src="/images/photo.jpg">')
      allow(described_class).to receive(:fetch_html).and_return(html)

      urls = described_class.image_candidates_for("https://example.com/recipes/tacos")

      expect(urls).to eq([ "https://example.com/images/photo.jpg" ])
    end

    it "prefers data-src, then the largest srcset candidate, over a lazy-load placeholder src" do
      html = html_with_images(
        json_ld_images: [],
        body: <<~BODY
          <img src="data:image/gif;base64,R0lGOD" data-src="https://example.com/real.jpg">
          <img src="data:image/gif;base64,R0lGOD" srcset="https://example.com/small.jpg 480w, https://example.com/large.jpg 1200w">
        BODY
      )
      allow(described_class).to receive(:fetch_html).and_return(html)

      urls = described_class.image_candidates_for("https://example.com/tacos")

      expect(urls).to contain_exactly("https://example.com/real.jpg", "https://example.com/large.jpg")
    end

    it "filters out logos, icons, and other small chrome images" do
      html = html_with_images(
        json_ld_images: [],
        body: <<~BODY
          <img src="https://example.com/site-logo.png">
          <img src="https://example.com/icon-share.svg">
          <img src="https://example.com/tiny.jpg" width="40" height="40">
          <img src="https://example.com/dish.jpg" width="800" height="600">
        BODY
      )
      allow(described_class).to receive(:fetch_html).and_return(html)

      urls = described_class.image_candidates_for("https://example.com/tacos")

      expect(urls).to eq([ "https://example.com/dish.jpg" ])
    end

    it "dedupes and caps the combined candidate list" do
      images = (1..30).map { |n| %(<img src="https://example.com/photo-#{n}.jpg">) }.join
      html = html_with_images(json_ld_images: [ "https://example.com/photo-1.jpg" ], body: images)
      allow(described_class).to receive(:fetch_html).and_return(html)

      urls = described_class.image_candidates_for("https://example.com/tacos")

      expect(urls.length).to eq(described_class::MAX_IMAGE_CANDIDATES)
      expect(urls.first).to eq("https://example.com/photo-1.jpg")
      expect(urls.uniq).to eq(urls)
    end

    it "returns an empty array when the recipe has no source_url" do
      expect(described_class.image_candidates_for(nil)).to eq([])
    end
  end

  describe ".from_text" do
    it "parses raw ingredient/instruction text and runs the autosorter" do
      user = create(:user)

      result = described_class.from_text(
        title: "Tacos",
        description: "Weeknight tacos",
        ingredients_text: "2 eggs\n1 cup flour",
        instructions_text: "Whisk the eggs.\nAdd the flour.",
        user: user
      )

      expect(result).to be_ok
      recipe = result.recipe
      expect(recipe.source_url).to be_nil
      expect(recipe.recipe_ingredients.map { |ri| [ ri.quantity, ri.unit, ri.ingredient.name ] })
        .to contain_exactly([ 2.0, nil, "eggs" ], [ 1.0, "cup", "flour" ])
      expect(recipe.instructions.pluck(:description)).to eq([ "Whisk the eggs.", "Add the flour." ])

      egg_step = recipe.instructions.find_by(description: "Whisk the eggs.")
      expect(egg_step.recipe_ingredients.map { |ri| ri.ingredient.name }).to eq([ "eggs" ])
    end

    it "falls back to a default description when none is given" do
      user = create(:user)

      result = described_class.from_text(
        title: "Tacos",
        description: "",
        ingredients_text: "salt to taste",
        instructions_text: "Season with salt.",
        user: user
      )

      expect(result.recipe.description).to eq("No description provided.")
    end

    it "strips checkbox glyphs, bullets, and numbered-list markers pasted from formatted lists" do
      user = create(:user)

      result = described_class.from_text(
        title: "Tacos",
        description: "Weeknight tacos",
        ingredients_text: "▢1 garlic clove, minced\n☑ 2 eggs\n— 1.5 cups flour\n* salt to taste",
        instructions_text: "1. Preheat the oven.\n2) Add the flour and stir.",
        user: user
      )

      expect(result).to be_ok
      recipe = result.recipe
      expect(recipe.recipe_ingredients.map { |ri| [ ri.quantity, ri.unit, ri.ingredient.name ] })
        .to contain_exactly(
          [ 1.0, "clove", "garlic" ],
          [ 2.0, nil, "eggs" ],
          [ 1.5, "cups", "flour" ],
          [ nil, nil, "salt to taste" ]
        )
      expect(recipe.instructions.pluck(:description)).to eq([ "Preheat the oven.", "Add the flour and stir." ])
    end
  end
end

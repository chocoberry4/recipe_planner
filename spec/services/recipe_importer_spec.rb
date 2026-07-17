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
  end
end

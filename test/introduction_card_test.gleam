import gleam/string
import gleeunit
import introduction_card.{type Model, Model}
import lustre/element

pub fn main() -> Nil {
  gleeunit.main()
}

fn sample_model(selected: Int) -> Model {
  Model(
    selected: selected,
    fact_index: 0,
    revealed_chars: 100,
    seed: 314,
    hold_ticks: 0,
  )
}

pub fn view_renders_the_boot_sequence_test() {
  let rendered =
    introduction_card.view(sample_model(-1)) |> element.to_string

  assert string.contains(rendered, "LOADING")
  assert string.contains(rendered, "CHECKING SYSTEM")
  assert string.contains(rendered, "Commencing System Check")
  assert string.contains(rendered, "Combat Preparations Complete")
}

pub fn view_renders_the_profile_and_destinations_test() {
  let rendered =
    introduction_card.view(sample_model(-1)) |> element.to_string

  assert string.contains(rendered, "PERSONAL DATA")
  assert string.contains(rendered, "SOFTWARE ENGINEER")
  assert string.contains(rendered, "GITHUB")
  assert string.contains(rendered, "Octopuses have three hearts.")
}

pub fn selected_destination_is_marked_active_test() {
  let rendered = introduction_card.view(sample_model(1)) |> element.to_string

  assert string.contains(rendered, "is-active")
}

pub fn glitch_layers_echo_the_text_test() {
  let rendered =
    introduction_card.view(sample_model(-1)) |> element.to_string

  assert string.contains(rendered, "data-text")
}

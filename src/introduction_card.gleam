//// A personal introduction card styled after the NieR:Automata interface,
//// rendered in a deep navy palette.
////
//// The whole page is one Gleam/Lustre program: the boot ("LOADING") sequence,
//// the glitch text effect, the Yorha-style navigation tabs and the footer are
//// all driven by CSS animations plus a tiny bit of Lustre state for the
//// currently highlighted destination.
////
//// Everything you are likely to want to edit lives in `destinations`,
//// `fields`, `loading_messages` and the identity constants below.

import gleam/int
import gleam/list
import gleam/result
import gleam/string
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// -----------------------------------------------------------------------------
// Boot sequence tunables
// -----------------------------------------------------------------------------

/// Milliseconds spent typing a single character of the boot log.
const char_speed_ms = 11

/// Delay before the first character is typed.
const boot_start_ms = 300

/// How long the completed boot log is held before the overlay fades away.
const boot_hold_ms = 1100

// -----------------------------------------------------------------------------
// Content — edit me
// -----------------------------------------------------------------------------

/// A destination shown as a top tab. `href` is where the visitor is sent.
type Destination {
  Destination(label: String, hint: String, href: String)
}

fn destinations() -> List(Destination) {
  [
    Destination(
      label: "GITHUB",
      hint: "SOURCE CODE & PROJECTS",
      href: "https://github.com/HeNeos",
    ),
    Destination(
      label: "BLOG",
      hint: "ARTICLES & NOTES",
      href: "https://heneos.github.io/heneos-blog",
    ),
    Destination(
      label: "LINKEDIN",
      hint: "PROFESSIONAL PROFILE",
      href: "https://www.linkedin.com/in/heneos",
    ),
    Destination(
      label: "EMAIL",
      hint: "DIRECT MESSAGE",
      href: "mailto:heneos3.14@gmail.com",
    ),
  ]
}

/// Small facts about you, rendered as the status readout.
/// TODO: Increase available width
fn fields() -> List(#(String, String)) {
  [
    #("DESIGNATION", "Software Engineer"),
    #("LOCATION", "EARTH |> near to IRELAND"),
    #("SPECIALIZATION", "Backend, systems and cloud architecture"),
    #("STACK", "python, typescript, rust, idris2, gleam, elixir"),
    #("STATUS", "AVAILABLE for work"),
    #(
      "INTERESTS",
      "distributed systems, PL, cloud arch, security eng, type theory",
    ),
  ]
}

/// The system-check lines typed out during boot. These mirror the YoRHa
/// start-up diagnostics.
fn loading_messages() -> List(String) {
  [
    "Commencing System Check",
    "Memory Unit: Green",
    "Initializing Tactics Log",
    "Loading Geographic Data",
    "Vitals: Green",
    "Remaining MP: 100%",
    "Black Box Temperature: Normal",
    "Black Box Internal Pressure: Normal",
    "Activating IFF",
    "Activating FCS",
    "Initializing Pod Connection",
    "Launching DBU Setup",
    "Activating Inertia Control System",
    "Activating Environmental Sensors",
    "Equipment Authentication: Complete",
    "Equipment Status: Green",
    "All Systems Green",
    "Combat Preparations Complete",
  ]
}

const document_title = "PERSONAL DATA"

const identifier = "314-HE·NEOS"

const callsign = "JOSUE HUAROTO V."

const subtitle = "UNIT " <> identifier <> " // " <> callsign

const summary = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam eget magna arcu. Maecenas ut consectetur lectus. Nunc nunc est, faucibus sed nisi nec, venenatis aliquet nibh. In nisl nulla"

const footer_tick_ms = 80

const footer_reveal_chars_per_tick = 2

const footer_hold_ticks = 45

const scramble_characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#%*+-=?"

fn fun_facts() -> List(String) {
  [
    "Octopuses have three hearts.",
    "A day on Venus is longer than its year.",
    "Wombat droppings are cube-shaped.",
    "The dot on an i or j is called a tittle.",
    "Bananas are berries, but strawberries are not.",
    "A group of flamingos is called a flamboyance.",
    "The Eiffel Tower grows slightly taller in summer.",
    "Honey can stay edible for thousands of years when sealed.",
  ]
}

// -----------------------------------------------------------------------------
// Boot timing
// -----------------------------------------------------------------------------

type LogRow {
  LogRow(text: String, chars: Int, duration_ms: Int, delay_ms: Int)
}

fn log_rows() -> List(LogRow) {
  log_rows_loop(loading_messages(), 0, [])
}

fn log_rows_loop(
  messages: List(String),
  elapsed: Int,
  acc: List(LogRow),
) -> List(LogRow) {
  case messages {
    [] -> list.reverse(acc)
    [message, ..rest] -> {
      let chars = string.length(message)
      let duration = chars * char_speed_ms
      let delay = boot_start_ms + elapsed
      let row = LogRow(message, chars, duration, delay)
      log_rows_loop(rest, elapsed + duration, [row, ..acc])
    }
  }
}

fn typing_ms() -> Int {
  list.fold(loading_messages(), 0, fn(total, message) {
    total + string.length(message) * char_speed_ms
  })
}

/// Total length of the boot sequence, exposed to CSS as `--boot-total`.
fn boot_total_ms() -> Int {
  boot_start_ms + typing_ms() + boot_hold_ms
}

// -----------------------------------------------------------------------------
// Model / update loop
// -----------------------------------------------------------------------------

pub type Model {
  Model(
    selected: Int,
    fact_index: Int,
    revealed_chars: Int,
    seed: Int,
    hold_ticks: Int,
  )
}

pub type Message {
  UserHoveredDestination(Int)
  UserFocusedDestination(Int)
  UserLeftDestinations
  FooterAnimationTick
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(Model, effect.Effect(Message)) {
  let seed = random_seed()
  let fact_index = positive_remainder(seed, list.length(fun_facts()))
  #(
    Model(
      selected: -1,
      fact_index: fact_index,
      revealed_chars: 0,
      seed: seed,
      hold_ticks: 0,
    ),
    effect.from(fn(dispatch) {
      start_footer_timer(footer_tick_ms, fn() { dispatch(FooterAnimationTick) })
    }),
  )
}

fn update(model: Model, message: Message) -> #(Model, effect.Effect(Message)) {
  case message {
    UserHoveredDestination(index) -> #(
      with_selected(model, index),
      effect.none(),
    )
    UserFocusedDestination(index) -> #(
      with_selected(model, index),
      effect.none(),
    )
    UserLeftDestinations -> #(with_selected(model, -1), effect.none())
    FooterAnimationTick -> #(advance_footer(model), effect.none())
  }
}

fn with_selected(model: Model, selected: Int) -> Model {
  Model(..model, selected: selected)
}

fn advance_footer(model: Model) -> Model {
  let fact = fun_fact_at(fun_facts(), model.fact_index)
  let fact_length = string.length(fact)
  case model.revealed_chars < fact_length {
    True ->
      Model(
        ..model,
        revealed_chars: model.revealed_chars + footer_reveal_chars_per_tick,
        seed: next_seed(model.seed),
        hold_ticks: 0,
      )
    False -> advance_footer_hold(model, fact_length)
  }
}

fn advance_footer_hold(model: Model, fact_length: Int) -> Model {
  case model.hold_ticks < footer_hold_ticks {
    True -> Model(..model, hold_ticks: model.hold_ticks + 1)
    False -> {
      let seed = next_seed(model.seed)
      let facts = fun_facts()
      let random_index = positive_remainder(seed, list.length(facts))
      let next_index = case random_index == model.fact_index {
        True -> positive_remainder(random_index + 1, list.length(facts))
        False -> random_index
      }
      Model(
        ..model,
        fact_index: next_index,
        revealed_chars: 0,
        seed: next_seed(seed + fact_length),
        hold_ticks: 0,
      )
    }
  }
}

fn next_seed(seed: Int) -> Int {
  positive_remainder(seed * 48_271, 2_147_483_647)
}

fn positive_remainder(dividend: Int, divisor: Int) -> Int {
  int.remainder(dividend, divisor) |> result.unwrap(or: 0)
}

fn fun_fact_at(facts: List(String), index: Int) -> String {
  case index {
    0 -> first_fun_fact(facts)
    _ -> fun_fact_at(list.drop(facts, 1), index - 1)
  }
}

fn first_fun_fact(facts: List(String)) -> String {
  case facts {
    [fact, ..] -> fact
    [] -> ""
  }
}

fn displayed_fun_fact(model: Model) -> String {
  let fact = fun_fact_at(fun_facts(), model.fact_index)
  scramble_text(fact, model.revealed_chars, model.seed, 0, "")
}

fn scramble_text(
  fact: String,
  revealed_chars: Int,
  seed: Int,
  index: Int,
  output: String,
) -> String {
  case index >= string.length(fact) {
    True -> output
    False -> {
      let character = string.slice(fact, index, 1)
      let seed = next_seed(seed)
      let displayed_character = case index < revealed_chars {
        True -> character
        False -> scrambled_character(character, seed)
      }
      scramble_text(
        fact,
        revealed_chars,
        seed,
        index + 1,
        output <> displayed_character,
      )
    }
  }
}

fn scrambled_character(character: String, seed: Int) -> String {
  case character == " " {
    True -> " "
    False ->
      string.slice(
        scramble_characters,
        positive_remainder(seed, string.length(scramble_characters)),
        1,
      )
  }
}

@external(javascript, "./introduction_card_ffi.mjs", "start_footer_timer")
fn start_footer_timer(milliseconds: Int, callback: fn() -> Nil) -> Nil

@external(javascript, "./introduction_card_ffi.mjs", "random_seed")
fn random_seed() -> Int

// -----------------------------------------------------------------------------
// View
// -----------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Message) {
  html.div(
    [
      attribute.class("nier"),
      attribute.style("--boot-total", int.to_string(boot_total_ms()) <> "ms"),
    ],
    [
      loader(),
      page(model),
    ],
  )
}

// -- boot overlay -------------------------------------------------------------

fn loader() -> Element(Message) {
  html.div([attribute.class("nier__loader"), attribute.aria("hidden", "true")], [
    html.div([attribute.class("nier__emblem")], []),
    html.header([attribute.class("nier__loader-head")], [
      html.div([attribute.class("nier__loader-status")], [
        glitch(html.h1, "nier__glitch nier__loader-title", "LOADING"),
        glitch(html.p, "nier__glitch nier__loader-sys", "- CHECKING SYSTEM"),
        html.span([attribute.class("nier__loader-dots")], []),
      ]),
      spinner(),
    ]),
    html.section(
      [attribute.class("nier__loader-logs")],
      list.map(log_rows(), log_line),
    ),
  ])
}

fn spinner() -> Element(Message) {
  html.div(
    [attribute.class("nier__spinner"), attribute.aria("hidden", "true")],
    [
      html.div([attribute.class("nier__spinner-inner")], []),
      html.div([attribute.class("nier__spinner-ring")], []),
      html.div([attribute.class("nier__spinner-outer")], []),
      html.div([attribute.class("nier__spinner-close")], []),
    ],
  )
}

fn log_line(row: LogRow) -> Element(Message) {
  html.p(
    [
      attribute.class("nier__glitch nier__log"),
      attribute.data("text", row.text),
      attribute.styles([
        #("--chars", int.to_string(row.chars)),
        #("--dur", int.to_string(row.duration_ms) <> "ms"),
        #("--delay", int.to_string(row.delay_ms) <> "ms"),
      ]),
    ],
    [html.text(row.text)],
  )
}

// -- main card ----------------------------------------------------------------

fn page(model: Model) -> Element(Message) {
  html.main([attribute.class("nier__page")], [
    topbar(model),
    html.hr([attribute.class("nier__hr")]),
    html.div([attribute.class("nier__dotted")], []),
    html.div([attribute.class("nier__body")], [
      masthead(),
      profile(),
    ]),
    page_footer(model),
  ])
}

fn topbar(model: Model) -> Element(Message) {
  html.header([attribute.class("nier__topbar")], [
    html.div([attribute.class("nier__bar-deco")], [
      html.span([attribute.class("nier__bar nier__bar--wide")], []),
      html.span([attribute.class("nier__bar nier__bar--thin")], []),
    ]),
    destination_tabs(model),
  ])
}

fn masthead() -> Element(Message) {
  html.div([attribute.class("nier__masthead")], [
    glitch(html.h1, "nier__glitch nier__title", document_title),
    glitch(html.h3, "nier__glitch nier__subtitle", subtitle),
  ])
}

fn profile() -> Element(Message) {
  html.div([attribute.class("nier__widget")], [
    html.div([attribute.class("nier__widget-head")], [
      html.span([attribute.class("nier__widget-square")], []),
      html.span([attribute.class("nier__widget-title")], [html.text("STATUS")]),
      html.span([attribute.class("nier__widget-level")], [
        html.text("ID " <> identifier),
      ]),
    ]),
    html.div([attribute.class("nier__widget-body")], [
      html.p([attribute.class("nier__summary")], [html.text(summary)]),
      html.dl(
        [attribute.class("nier__fields")],
        fields() |> list.index_map(field_row),
      ),
    ]),
  ])
}

fn field_row(field: #(String, String), index: Int) -> Element(Message) {
  let #(label, value) = field
  html.div(
    [
      attribute.class("nier__field"),
      attribute.style("--i", int.to_string(index)),
    ],
    [
      html.dt([attribute.class("nier__field-label")], [html.text(label)]),
      html.dd([attribute.class("nier__field-value")], [html.text(value)]),
    ],
  )
}

fn destination_tabs(model: Model) -> Element(Message) {
  html.nav(
    [
      attribute.class("nier__tabs"),
      attribute.aria("label", "Destinations"),
      event.on_mouse_leave(UserLeftDestinations),
    ],
    destinations()
      |> list.index_map(fn(destination, index) {
        destination_item(model, destination, index)
      }),
  )
}

fn destination_item(
  model: Model,
  destination: Destination,
  index: Int,
) -> Element(Message) {
  html.a(
    [
      attribute.classes([
        #("nier__link", True),
        #("is-active", index == model.selected),
      ]),
      attribute.style("--i", int.to_string(index)),
      attribute.href(destination.href),
      attribute.target("_blank"),
      attribute.rel("noopener noreferrer"),
      attribute.title(destination.hint),
      event.on_mouse_enter(UserHoveredDestination(index)),
      event.on_focus(UserFocusedDestination(index)),
    ],
    [
      html.span([attribute.class("nier__icon")], []),
      html.span([attribute.class("nier__link-label")], [
        html.text(destination.label),
      ]),
    ],
  )
}

fn page_footer(model: Model) -> Element(Message) {
  html.footer([attribute.class("nier__footer")], [
    html.div([attribute.class("nier__footer-bars")], [
      html.span(
        [attribute.class("nier__bar nier__bar--wide nier__bar--dark")],
        [],
      ),
      html.span(
        [attribute.class("nier__bar nier__bar--thin nier__bar--dark")],
        [],
      ),
    ]),
    html.span([attribute.class("nier__footer-text")], [
      html.text(displayed_fun_fact(model)),
    ]),
  ])
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

/// Builds an element inside a glitch wrapper. The element text is duplicated
/// into `data-text` so the CSS `::before`/`::after` layers can echo it.
fn glitch(
  builder: fn(List(attribute.Attribute(Message)), List(Element(Message))) ->
    Element(Message),
  classes: String,
  text: String,
) -> Element(Message) {
  builder([attribute.class(classes), attribute.data("text", text)], [
    html.text(text),
  ])
}

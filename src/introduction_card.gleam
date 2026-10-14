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
      label: "WEBSITE",
      hint: "ARTICLES & NOTES",
      href: "https://your-website.example.com",
    ),
    Destination(
      label: "LINKEDIN",
      hint: "PROFESSIONAL PROFILE",
      href: "https://www.linkedin.com/in/your-username",
    ),
    Destination(
      label: "EMAIL",
      hint: "DIRECT MESSAGE",
      href: "mailto:you@example.com",
    ),
  ]
}

/// Small facts about you, rendered as the status readout.
fn fields() -> List(#(String, String)) {
  [
    #("DESIGNATION", "SOFTWARE ENGINEER"),
    #("LOCATION", "REMOTE / EARTH"),
    #("SPECIALIZATION", "BACKEND & SYSTEMS"),
    #("STACK", "GLEAM · ELIXIR · RUST"),
    #("STATUS", "AVAILABLE FOR WORK"),
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

const identifier = "002-E"

const callsign = "HENEOS"

const subtitle = "UNIT " <> identifier <> " // " <> callsign

const summary = "A software engineer who builds reliable systems and treats
the craft of programming as a discipline worth mastering. I care about
correctness, clear design, and software that stays easy to change."

const footer_text = "SELECT A DESTINATION TO TRANSMIT"

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
  Model(selected: Int)
}

pub type Message {
  UserHoveredDestination(Int)
  UserFocusedDestination(Int)
  UserLeftDestinations
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(Model, effect.Effect(Message)) {
  #(Model(selected: -1), effect.none())
}

fn update(_model: Model, message: Message) -> #(Model, effect.Effect(Message)) {
  let selected = case message {
    UserHoveredDestination(index) -> index
    UserFocusedDestination(index) -> index
    UserLeftDestinations -> -1
  }

  #(Model(selected: selected), effect.none())
}

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
    page_footer(),
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

fn page_footer() -> Element(Message) {
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
    html.span([attribute.class("nier__footer-text")], [html.text(footer_text)]),
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

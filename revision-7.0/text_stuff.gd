extends Node

# Put your Gemini API key here (REALLY IMPORTANT -- MUST BE FILLED)
const API_KEY = ""

@onready var http_request = $GeminiRequest
@onready var label = $RichTextLabel

# Storage stuff
var question_bank = [] 
var current_index = 0

# Your Revision Text, Shove it in here
var revision_context = """
WJEC BIOLOGY 1.5: PLANT TRANSPORT, NUTRITION, AND PHYSIOLOGICAL MECHANISMS (MAXIMUM DETAIL)

I. THE VASCULAR BUNDLE: STRUCTURAL DIFFERENTIATION
Plants possess a highly specialized internal transport infrastructure categorized into vascular bundles, which are arranged differently in the roots (central core) and the stems (peripheral ring).
1. XYLEM VESSELS: These consist of an elongated, continuous column of dead, hollowed-out cells (tracheids and vessel elements). Their primary structural characteristic is the deposition of Lignin—a complex, waterproof carbohydrate polymer—in the cell walls. Lignin provides exceptional compressive strength to withstand the negative pressure of the transpiration pull and prevents the vessels from collapsing. Xylem facilitates the unidirectional transport of water and dissolved mineral ions (such as nitrates for protein synthesis and magnesium for chlorophyll production) from the subterranean root system to the aerial foliage.
2. PHLOEM TISSUE: This is a complex, living tissue composed of Sieve Tube Elements and Companion Cells. Sieve tubes lack a nucleus and most organelles to provide an unobstructed path for the translocation of photosynthates. They are connected by Sieve Plates—perforated end-walls that allow the pressure-driven flow of sap. Companion Cells are metabolically hyperactive, containing numerous mitochondria to generate the Adenosine Triphosphate (ATP) required for the active loading of sugars into the sieve tubes.

II. TRANSLOCATION: THE SOURCE-TO-SINK MECHANISM
Translocation is the bidirectional movement of organic solutes, primarily sucrose and amino acids, through the phloem. 
1. SOURCES: Regions of the plant where sugars are produced (primarily the palisade mesophyll in leaves during photosynthesis) or mobilized from storage.
2. SINKS: Regions where sugars are consumed or stored, such as growing meristems (roots and shoot tips), developing fruits, or storage organs like tubers.
The movement occurs via mass flow, driven by a hydrostatic pressure gradient created by the active transport of sucrose into the phloem, followed by the osmotic entry of water.

III. THE TRANSPIRATION STREAM AND STOMATAL KINETICS
Transpiration is the unavoidable consequence of gas exchange, involving the evaporation of water from the moist cell walls of the spongy mesophyll into the sub-stomataspace, followed by diffusion out through the stomata.
1. STOMATAL MECHANISM: Stomata are microscopic apertures regulated by a pair of specialized epidermal cells called Guard Cells. When these cells actively pump potassium ions (K+) into their cytoplasm, their water potential decreases, causing water to enter via osmosis. The guard cells become Turgid; due to their asymmetrically thickened inner cell walls, they bow outward, creating an opening (the stoma). Conversely, when water leaves, the cells become Flaccid, and the stoma closes to prevent desiccation.
2. ENVIRONMENTAL MODULATORS:
   - Light Intensity: Photosynthesis reduces internal CO2 concentrations, triggering stomatal opening.
   - Temperature: Increases the kinetic energy and vapor pressure of water molecules, accelerating evaporation rates.
   - Humidity: A high external water vapor concentration reduces the water potential gradient between the leaf interior and the atmosphere, significantly inhibiting transpiration.
   - Wind Speed: Removes the stationary boundary layer of humid air surrounding the leaf, maintaining a steep concentration gradient for rapid diffusion.

IV. ROOT PHYSIOLOGY: OSMOSIS AND ACTIVE TRANSPORT
The interface between the plant and the soil is the Root Hair Cell, an epidermal cell with a long, lateral extension that maximizes the surface area for absorption.
1. OSMOSIS: Water moves from the soil (high water potential) into the root hair cell (lower water potential) across a partially permeable plasma membrane. This movement is passive and follows a potential gradient.
2. ACTIVE TRANSPORT: Essential mineral ions, such as Nitrates (NO3-) and Phosphates (PO4^3-), are often present in the soil at much lower concentrations than within the root cell. To absorb these against the concentration gradient, the cell utilizes specialized carrier proteins and metabolic energy (ATP). This process is highly dependent on aerobic respiration within the root mitochondria; therefore, waterlogged or compacted soil (lacking oxygen) can inhibit mineral uptake and lead to nutrient deficiencies.

V. QUANTITATIVE ANALYSIS: THE POTOMETER
The rate of transpiration can be experimentally quantified using a Potometer. This apparatus measures water uptake (which is roughly equivalent to water loss). A leafy shoot is sealed into the device using a watertight rubber bung. An air bubble is introduced into the capillary tube; the distance this bubble travels over a precise temporal interval allows for the calculation of the transpiration rate (Volume = πr²h).
"""

func _ready():
	http_request.request_completed.connect(_on_request_completed)
	
	label.text = "Loading questions from AI..."
	generate_questions()
	
func _process(delta: float) -> void:
	
	pass

func generate_questions():
	# the url for gemini 1.5, (kinda horrible but it works so i dont care)
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=" + API_KEY
	
	# The Prompt: We instruct the AI to act as a revision tool and output strictly JSON
	var prompt_text = "Analyze the following text and create a flashcard for each thing mentioned. " + \
	"The format must be a JSON Array with 'question' (with blanks like ____) and 'answer'. " + \
	"Do not use Markdown formatting. Raw JSON only. " + \
	"Text to analyze: " + revision_context
	
	var payload = {
		"contents": [{
			"parts": [{"text": prompt_text}]
		}]
	}
	
	var headers = ["Content-Type: application/json"]
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var response_data = json.get_data()
			var ai_text = response_data["candidates"][0]["content"]["parts"][0]["text"]
			
			ai_text = ai_text.replace("```json", "").replace("```", "").strip_edges()
			
			var final_questions = JSON.parse_string(ai_text)
			
			if final_questions:
				question_bank = final_questions
				current_index = 0
				show_question()
			else:
				label.text = "Error parsing AI questions."
	else:
		label.text = "Connection Error: " + str(response_code)

func show_question():
	if question_bank.is_empty(): return
	
	var card = question_bank[current_index]
	label.text = "Q: " + card["question"]

func show_answer():
	if question_bank.is_empty(): return
	
	var card = question_bank[current_index]
	label.text = "A: " + card["answer"]

func _input(event):
	#Click 1 to view the question (you can switch between Question and Answer)
	if event is InputEventKey and event.pressed and event.keycode == KEY_1:
		show_question()
		
	#Click Q to view the answer (you can switch between Question and Answer)
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		show_answer()
		
	#Space goes to next card, you cant go back until you loop around by looking at every card.
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		current_index = (current_index + 1) % question_bank.size()
		show_question()

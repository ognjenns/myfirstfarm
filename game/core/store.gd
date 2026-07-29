extends Node
## Autoload "Store" — kupovina "Unlock all games" preko Google Play Billing.
## Van Androida (editor; iOS dobija StoreKit kasnije) tiho neaktivan,
## a UI u roditeljskom uglu tada pada na debug test-prekidač.

signal unlock_state_changed
signal purchase_failed(message: String)

const PRODUCT_ID := "unlock_all"

var available := false     # Billing konektovan I proizvod postoji u Play konzoli
var price_text := "€2.99"  # zameni se pravom lokalizovanom cenom iz Play-a

var _bc: BillingClient = null

func _ready() -> void:
	if OS.get_name() != "Android" or not Engine.has_singleton("GodotGooglePlayBilling"):
		return
	_bc = BillingClient.new()
	add_child(_bc)
	_bc.connected.connect(_on_connected)
	_bc.query_product_details_response.connect(_on_product_details)
	_bc.on_purchase_updated.connect(_on_purchases)
	_bc.query_purchases_response.connect(_on_purchases)
	_bc.start_connection()

func _on_connected() -> void:
	_bc.query_product_details([PRODUCT_ID], BillingClient.ProductType.INAPP)
	_bc.query_purchases(BillingClient.ProductType.INAPP)  # tihi restore na startu

func _on_product_details(resp: Dictionary) -> void:
	if resp.get("response_code") != BillingClient.BillingResponseCode.OK:
		return
	for pd in resp.get("product_details", []):
		if pd.get("product_id", "") != PRODUCT_ID:
			continue
		available = true
		var offer: Dictionary = pd.get("one_time_purchase_offer_details", {})
		if offer.has("formatted_price"):
			price_text = str(offer.formatted_price)

func buy() -> void:
	if available:
		_bc.purchase(PRODUCT_ID)

func restore() -> void:
	if _bc:
		_bc.query_purchases(BillingClient.ProductType.INAPP)

func _on_purchases(resp: Dictionary) -> void:
	if resp.get("response_code") != BillingClient.BillingResponseCode.OK:
		if resp.get("response_code") != BillingClient.BillingResponseCode.USER_CANCELED:
			purchase_failed.emit(str(resp.get("debug_message", "")))
		return
	for p in resp.get("purchases", []):
		_handle_purchase(p)

func _handle_purchase(p: Dictionary) -> void:
	if int(p.get("purchase_state", 0)) != BillingClient.PurchaseState.PURCHASED:
		return
	if PRODUCT_ID not in p.get("product_ids", []):
		return
	# Play zahteva potvrdu u roku od 3 dana ili vraća novac
	if not bool(p.get("is_acknowledged", false)):
		_bc.acknowledge_purchase(str(p.get("purchase_token", "")))
	if not Save.unlocked:
		Save.set_unlocked(true)
	unlock_state_changed.emit()

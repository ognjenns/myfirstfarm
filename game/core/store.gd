extends Node
## Autoload "Store" — kupovina "Unlock all games".
## Android: Google Play Billing (zvanični GodotGooglePlayBilling plugin).
## iOS: StoreKit 2 preko OpenIAP godot-iap addona (samo iOS deo, Android
## delovi addona su uklonjeni). Van mobilnih platformi tiho neaktivan.

signal unlock_state_changed
signal purchase_failed(message: String)

const PRODUCT_ID := "unlock_all"
const IapTypes = preload("res://addons/godot-iap/types.gd")

var available := false     # store konektovan I proizvod postoji
var price_text := "$2.99"  # zameni se pravom lokalizovanom cenom iz store-a

var _bc: BillingClient = null  # Android
var _iap: Node = null          # iOS (GodotIapPlugin autoload)

func _ready() -> void:
	match OS.get_name():
		"Android":
			if Engine.has_singleton("GodotGooglePlayBilling"):
				_init_android()
		"iOS":
			_init_ios()

func buy() -> void:
	if not available:
		return
	if _bc:
		_bc.purchase(PRODUCT_ID)
	elif _iap:
		var apple = IapTypes.RequestPurchaseIosProps.new()
		apple.sku = PRODUCT_ID
		var platforms = IapTypes.RequestPurchasePropsByPlatforms.new()
		platforms.apple = apple
		# _raw varijanta da bismo videli kompletan rezultat (uspeh/greška) u logu;
		# ishod stiže i kroz purchase_updated/purchase_error, ALI na iOS-u ume da
		# dođe SAMO u povratnoj vrednosti (npr. već kupljeno → nema sheeta) — pa
		# rezultat i obrađujemo, ne samo logujemo. _handle_ios_purchase je
		# idempotentan, duplo otključavanje nije problem.
		var res: Dictionary = _iap._request_purchase_raw(IapTypes.RequestPurchaseProps.in_app(platforms).to_dict())
		print("[Store] request_purchase rezultat: ", res)
		if res.get("success", false):
			_handle_ios_purchase(_iap._normalize_purchase_dict(res), true)

func restore() -> void:
	if _bc:
		_bc.query_purchases(BillingClient.ProductType.INAPP)
	elif _iap:
		_restore_ios()

func _unlock() -> void:
	if not Save.unlocked:
		Save.set_unlocked(true)
	unlock_state_changed.emit()

# ============================== ANDROID =================================

func _init_android() -> void:
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
	_unlock()

# ================================ iOS ===================================

func _init_ios() -> void:
	_iap = get_node_or_null("/root/GodotIapPlugin")
	if _iap == null:
		return
	_iap.connected.connect(_on_ios_connected)
	_iap.purchase_updated.connect(_on_ios_purchase_updated)
	_iap.purchase_error.connect(_on_ios_purchase_error)
	_iap.init_connection()

func _on_ios_connected() -> void:
	var req = IapTypes.ProductRequest.new()
	var skus: Array[String] = [PRODUCT_ID]  # skus je tipizirani Array[String]
	req.skus = skus
	req.type = IapTypes.ProductQueryType.IN_APP
	var products: Array = await _iap.fetch_products(req)
	print("[Store] iOS fetch_products vratio %d proizvod(a)" % products.size())
	for p in products:
		var d: Dictionary = p.to_dict() if p != null and p.has_method("to_dict") else {}
		print("[Store] proizvod: ", d)
		if str(d.get("id", d.get("productId", ""))) == PRODUCT_ID:
			available = true
			var price := str(d.get("displayPrice", d.get("display_price", "")))
			if price != "":
				price_text = price
	_restore_ios()  # tihi restore na startu

func _restore_ios() -> void:
	var purchases: Array = await _iap.get_available_purchases()
	for pu in purchases:
		var d: Dictionary = pu.to_dict() if pu != null and pu.has_method("to_dict") else {}
		_handle_ios_purchase(d, false)

## finish=true za sveže kupovine (StoreKit traži da se transakcija zatvori);
## restore rezultati su već zatvoreni pa ih ne diramo.
func _handle_ios_purchase(d: Dictionary, finish: bool) -> void:
	if d.is_empty():
		return
	var pid := str(d.get("productId", d.get("product_id", d.get("id", ""))))
	var ids: Array = d.get("ids", [])
	if pid != PRODUCT_ID and PRODUCT_ID not in ids:
		return
	if finish:
		_iap.finish_transaction_dict(d, false)  # non-consumable → acknowledge
	_unlock()

func _on_ios_purchase_updated(purchase: Dictionary) -> void:
	print("[Store] purchase_updated: ", purchase)
	_handle_ios_purchase(purchase, true)

func _on_ios_purchase_error(err: Dictionary) -> void:
	print("[Store] purchase_error: ", err)
	var code := str(err.get("code", ""))
	if code != "user-cancelled" and code != "E_USER_CANCELLED":
		purchase_failed.emit(str(err.get("message", "")))

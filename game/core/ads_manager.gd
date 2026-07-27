extends Node
## Autoload "Ads" — apstrakcija nad AdMob-om, spremna za Poing Studios plugin (N5).
## Na desktopu i bez plugina: no-op. Pravila iz DESIGN.md ugrađena OVDE:
##  - reklama SAMO na prelazu mini-igra → hub
##  - najviše 1 na MIN_INTERVAL sekundi
##  - nikad ako je kupljeno "ukloni reklame"
## Kad se doda plugin: child-directed tag, NPA, max rating G — podesiti u _init_admob().

const MIN_INTERVAL := 180.0  # sekundi između interstitial-a

var _last_ad_time := -MIN_INTERVAL  # prva reklama tek posle prvog intervala igranja
var _plugin_ready := false

func _ready() -> void:
	_init_admob()

func _init_admob() -> void:
	# TODO (N5): Poing Studios godot-admob-plugin
	#  - MobileAds.set_request_configuration: tag_for_child_directed_treatment = TRUE,
	#    max_ad_content_rating = "G"
	#  - samo nepersonalizovane reklame (NPA) + UMP consent
	#  - učitati interstitial sa TEST ad unit ID dok se ne otvori AdMob nalog
	_plugin_ready = false

## Zove se na povratku iz mini-igre na hub. Vraća true ako je reklama prikazana.
func maybe_show_interstitial() -> bool:
	if Save.ads_removed:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_ad_time < MIN_INTERVAL:
		return false
	if not _plugin_ready:
		return false
	_last_ad_time = now
	# TODO (N5): interstitial.show()
	return true

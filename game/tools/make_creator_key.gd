extends Node
## ONE-TIME owner tool: creates the creator signing key.
##   private -> ~/Desktop/Subjugated Dialectics NFT/_BLACKBOX/creator_private.key   (never published)
##   public  -> game/export/creator_public.pem   (ships with the game + web viewer)
## Refuses to overwrite an existing private key. Run the scene tools/make_creator_key.tscn.

func _ready() -> void:
	var bb := Blackbox.dir_for(NftPackage.default_root())
	var r := Signer.generate_keys(bb, ProjectSettings.globalize_path("res://export"))
	var l := Label.new()
	l.text = ("Creator key created.\nPrivate: %s\nPublic: %s\n\nBack up the private key. Re-export the web viewer so it carries the public key." % [r.private, r.public]) if r.ok else ("Not created: " + r.reason)
	l.position = Vector2(32, 32)
	add_child(l)
	print("MAKE_CREATOR_KEY ", "OK" if r.ok else r.reason)

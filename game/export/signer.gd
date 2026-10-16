class_name Signer
extends RefCounted
## Creator signature: RSA-2048 / SHA-256 via Godot's Crypto (works on desktop and web).
## The private key lives only in the owner's BLACKBOX; the public key ships with the game/viewer so anyone can
## check that a piece was extracted and signed by the creator.

const MESSAGE := "SUBJUGATED-DIALECTICS|%s|%s|%d" # log hash · canonical code · edition number
const PRIVATE_FILE := "creator_private.key"
const PUBLIC_FILE := "creator_public.pem"


static func message(log_hash: String, code: String, edition: int) -> String:
	return MESSAGE % [log_hash, code, edition]


## Writes a new key pair: private into `private_dir`, public into `public_dir`. Refuses to overwrite a private key.
static func generate_keys(private_dir: String, public_dir: String) -> Dictionary:
	var priv := private_dir.path_join(PRIVATE_FILE)
	if FileAccess.file_exists(priv):
		return {"ok": false, "reason": "a creator key already exists — refusing to overwrite it"}
	DirAccess.make_dir_recursive_absolute(private_dir)
	DirAccess.make_dir_recursive_absolute(public_dir)
	var key := Crypto.new().generate_rsa(2048)
	if key.save(priv, false) != OK or key.save(public_dir.path_join(PUBLIC_FILE), true) != OK:
		return {"ok": false, "reason": "cannot write key files"}
	return {"ok": true, "private": priv, "public": public_dir.path_join(PUBLIC_FILE)}


static func sign(private_key_path: String, msg: String) -> String:
	var key := CryptoKey.new()
	if key.load(private_key_path, false) != OK:
		return ""
	var sig := Crypto.new().sign(HashingContext.HASH_SHA256, msg.sha256_buffer(), key)
	return Marshalls.raw_to_base64(sig)


static func verify(public_pem: String, msg: String, sig_b64: String) -> bool:
	if public_pem == "" or sig_b64 == "":
		return false
	var key := CryptoKey.new()
	if key.load_from_string(public_pem, true) != OK:
		return false
	return Crypto.new().verify(HashingContext.HASH_SHA256, msg.sha256_buffer(), Marshalls.base64_to_raw(sig_b64), key)

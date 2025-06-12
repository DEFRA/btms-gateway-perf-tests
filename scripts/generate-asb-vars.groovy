import java.net.URLEncoder
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import java.util.Base64


String connStr = args[0]
int expiryInSeconds = args.length > 1 ? args[1].toInteger() : 3600

if (!connStr) {
    log.error("Missing connection string in args[0]")
    throw new IllegalArgumentException("Missing ConnectionString")
}

// log.info("connStr: " + connStr)
Map parseAsbConnectionString(String str) {
    def map = [:]
    str.split(';').each {
        def kv = it.split('=', 2)
        if (kv.length == 2) {
            map[kv[0].trim()] = kv[1].trim()
        }
    }
    if (map["Endpoint"]) {
        map["Endpoint"] = map["Endpoint"]
            .replaceFirst("^sb://", "")
            .replaceAll(/\/$/, "")
    }
    return map
}

def asb = parseAsbConnectionString(connStr)

def host = asb.Endpoint
def entityPath = asb.EntityPath
def fullUri = "https://${host}/${entityPath}"
def path = "/${entityPath}/messages"

vars.put("asb_host", host)
vars.put("asb_path", path)
vars.put("asb_resourceUri", fullUri)
vars.put("asb_keyName", asb.SharedAccessKeyName)
vars.put("asb_key", asb.SharedAccessKey)

// Generate Token
String uri = fullUri
String keyName = asb.SharedAccessKeyName
String key = asb.SharedAccessKey

long expiry = (System.currentTimeMillis() / 1000) + expiryInSeconds
String rawUri = uri
String encodedUri = URLEncoder.encode(rawUri, "UTF-8")
String stringToSign = "${encodedUri}\n${expiry}"

Mac hmac = Mac.getInstance("HmacSHA256")
SecretKeySpec secretKey = new SecretKeySpec(key.getBytes("UTF-8"), "HmacSHA256")
hmac.init(secretKey)
byte[] signatureBytes = hmac.doFinal(stringToSign.getBytes("UTF-8"))
String encodedSignature = URLEncoder.encode(Base64.encoder.encodeToString(signatureBytes), "UTF-8")

String token = "SharedAccessSignature sr=${encodedUri}&sig=${encodedSignature}&se=${expiry}&skn=${keyName}"
vars.put("ASB_AUTH_TOKEN", token)

log.info("asb_host: " +  host)
log.info("asb_path: " +  path)
// log.info("ASB_AUTH_TOKEN: " + token)
log.info("Generated SAS token for: ${entityPath}")

SampleResult.setIgnore()

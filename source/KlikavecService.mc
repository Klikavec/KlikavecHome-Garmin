using Toybox.Lang;
using Toybox.Communications;

// Keep upstream action transport; templates have a different response MIME type.
class KlikavecService extends HomeAssistantService {
    function initialize() {HomeAssistantService.initialize();}
    function callTemplate(url,data,callback) {
        Communications.makeWebRequest(url,data,{
            :method=>Communications.HTTP_REQUEST_METHOD_POST,
            :headers=>Settings.augmentHttpHeaders({
                "Content-Type"=>Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization"=>"Bearer "+Settings.getApiKey()
            }),
            :responseType=>Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        },callback);
    }
}

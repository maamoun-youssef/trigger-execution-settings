/**
 * @author ULiT
 * @date 01/09/2021
 * @description a class that contains invocable method returning internal org url to be called in flows 
 **/
public class GetBaseURLInvocable {
    /**
     * @description a method to be called in flows to get the base url for the internal org
     * @return String internal org url
     **/
    @InvocableMethod(label='get Base URL Invocable' description='get Base URL Invocable')
    public static List<String> getBaseURLActionInvocable() {
        String baseURL = URL.getOrgDomainUrl().toExternalForm();
        return new List<String>{baseURL};
    }
}
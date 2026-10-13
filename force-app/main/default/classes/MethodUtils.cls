/**
 * @author ULiT
 * @date 23/08/2024
 * @description Use to check existing classes and methodes
 *******************************************************************************************************/
public with sharing class MethodUtils {
    
    public interface MethodChecker {
        Boolean hasMethod(String methodName);
        Object invoke(String methodName, List<Object> args);
    }
    
    public static Boolean doesClassExist(String className) {
        String namespacePrefix = className.contains('.') ? className.split('\\.').get(0) : null;
        className = className.contains('.') ? className.split('\\.').get(1) : className;
        List<ApexClass> classes = [SELECT Id FROM ApexClass WHERE Name = :className AND NamespacePrefix = :namespacePrefix LIMIT 1];
        return !classes.isEmpty();
    }
    
    public static Boolean doesMethodExist(String className, String methodName) {
        try {
            // Get the Type instance for the class
            Type classType = Type.forName(className);
            if (classType == null) {
                return false;
            }
            // Create an instance of the class
            MethodChecker instance = (MethodChecker) classType.newInstance();
            // Check if the method exists
            return instance.hasMethod(methodName);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return false;
        }
    }

    public static Object invokeMethod(String className, String methodName, List<Object> args) {
        try {
            // Get the Type instance for the class
            Type classType = Type.forName(className);
            if (classType == null) {
                return null;
            }
            // Create an instance of the class
            MethodChecker instance = (MethodChecker) classType.newInstance();
            // Invoke the method
            return instance.invoke(methodName, args);
        } catch (Exception e) {
            System.debug('Exception : ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('Exception: ' + e.getStackTraceString());
            return null;
        }
    }
}
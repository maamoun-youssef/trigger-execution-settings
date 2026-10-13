global interface BatchFactory {
    Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap);
}
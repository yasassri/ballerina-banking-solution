package org.abc.db;

import ballerina.data.sql;

public function getUserInfoWithID(int userid)(json result, error err){

    endpoint<sql:ClientConnector> ep {}
    bind sqlCon with ep;

    sql:Parameter[] parameters = [];
    string query_customerInfo = "SELECT * FROM Customer_Info WHERE user_id=?";

    try {
        //Obtaining customer information by passing userid
        sql:Parameter para1 = {sqlType:sql:Type.INTEGER, value:userid, direction:sql:Direction.IN};
        parameters = [para1];
        datatable dt = ep.select(query_customerInfo, parameters);
        var j, _ = <json>dt;
        result = j;
    } catch (error e) {
        err = e;
    }
    return;
}


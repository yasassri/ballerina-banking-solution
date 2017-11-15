package org.abc.util;

import ballerina.data.sql;
import ballerina.log;
import org.abc.beans as beans;
import org.abc.error as bError;
import ballerina.math;


function getUserID (int accountNumber) (int userID, error err) {
    endpoint<sql:ClientConnector> ep {
        init();
    }
    sql:Parameter[] parameters = [];
    TypeCastError ex;
    beans:TokenGen tg;
    string query_account = "SELECT user_id FROM Account WHERE acc_number=?";

    try {
        //Obtaining user id from the database by passing the account no
        sql:Parameter para1 = {sqlType:"integer", value:accountNumber, direction:0};
        parameters = [para1];
        datatable dt = ep.select(query_account, parameters);
        while (dt.hasNext()) {
            any dataStruct = dt.getNext();
            tg, ex = (beans:TokenGen)dataStruct;
            if (ex == null) {
                userID = tg.user_id;
            }
            else {
                log:printErrorCause("TokenGen:error in struct casting", (error)ex);
                break;
            }
        }
    } catch (error e) {
        err = e;
    }
    return;
}

function checkTokenExistance (int userID) (boolean exist, string otpCreatedTime, error err) {
    endpoint<sql:ClientConnector> ep {
        init();
    }
    sql:Parameter[] parameters = [];
    string query_tokenInfo = "SELECT otp_id, created_date FROM OTP_Info WHERE user_id=?";
    TypeCastError ex;
    beans:TokenValidity tv;
    exist = false;

    try {
        //Checking token existence against user id in database
        sql:Parameter para1 = {sqlType:"integer", value:userID, direction:0};
        parameters = [para1];
        datatable dt = ep.select(query_tokenInfo, parameters);

        while (dt.hasNext()) {
            exist = true;
            any dataStruct = dt.getNext();
            tv, ex = (beans:TokenValidity)dataStruct;
            println("c");
            if (ex != null) {
                log:printErrorCause("TokenGen:error in struct casting", (error)ex);
                println("d");
            }
            else {
                println("e");
                println(tv.created_date);
                otpCreatedTime = tv.created_date;
            }
        }
    } catch (error e) {
        err = e;
    }
    return;
}

function insertGenToken (int userid, string token) {
    endpoint<sql:ClientConnector> ep {
        init();
    }
    error err;
    sql:Parameter[] parameters = [];
    string query_tokenInfo = "INSERT INTO OTP_Info (otp_id, created_date, user_id) VALUES (?, ?, ?)";
    Time currentTimestamp = currentTime();

    try {
        //Inserting generated token to database
        sql:Parameter para1 = {sqlType:"varchar", value:token, direction:0};
        sql:Parameter para2 = {sqlType:"timestamp", value:currentTimestamp, direction:0};
        sql:Parameter para3 = {sqlType:"integer", value:userid, direction:0};
        parameters = [para1, para2, para3];
        var count, ids = ep.updateWithGeneratedKeys(query_tokenInfo, parameters, null);
    } catch (error e) {
        err = e;
    }
}

public function getCustomerInfo (int userid) (json result, error err) {
    endpoint<sql:ClientConnector> ep {
        init();
    }
    sql:Parameter[] parameters = [];
    TypeCastError ex;
    beans:TokenGen tg;
    string query_customerInfo = "SELECT * FROM Customer_Info WHERE user_id=?";

    try {
        //Obtaining customer information by passing userid
        sql:Parameter para1 = {sqlType:"integer", value:userid, direction:0};
        parameters = [para1];
        datatable dt = ep.select(query_customerInfo, parameters);
        var j, _ = <json>dt;
        result = j;
    } catch (error e) {
        err = e;
    }
    return;
}

public function getBalanceByAccountNumber (int accountNumber) (float balance, error err, bError:BackendError bErr) {
    endpoint<sql:ClientConnector> ep {
        create sql:ClientConnector(sql:MYSQL, "192.168.48.209", 3306, "Bank", "root", "root", {maximumPoolSize:1});
    }
    sql:Parameter[] parameters = [];
    TypeCastError ex;
    boolean b = true;
    beans:AccountBalance bal;
    string query = "SELECT current_balance from Account WHERE acc_number=?";

    try {
        sql:Parameter para1 = {sqlType:"integer", value:accountNumber, direction:0};
        parameters = [para1];
        datatable dt = ep.select(query, parameters);
        while (dt.hasNext()) {
            b = false;
            any dataStruct = dt.getNext();
            println(dataStruct);

            bal, ex = (beans:AccountBalance)dataStruct;
            if (ex == null) {
                balance = bal.current_balance;
                println(balance);
            }
            else {
                log:printErrorCause("AccountBalance:error in struct casting", (error)ex);
                break;
            }
        }

        if (b) {
            bErr = {status_code:402, error_message:"Invalid account number"};

        }
    } catch (error e) {
        err = e;
    }
    return;
}


public function getBalanceByUser (int userid) (json balance, error err, bError:BackendError bErr) {
    endpoint<sql:ClientConnector> ep {
        create sql:ClientConnector(sql:MYSQL, "192.168.48.209", 3306, "Bank", "root", "root", {maximumPoolSize:5});
    }
    sql:Parameter[] parameters = [];
    TypeCastError ex;
    TypeConversionError er;
    string query = "SELECT acc_number, current_balance from Account WHERE user_id=?";

    try {
        sql:Parameter para1 = {sqlType:"integer", value:userid, direction:0};
        parameters = [para1];
        datatable dt = ep.select(query, parameters);
        balance, er = <json>dt;
        println(balance);

    }
    catch (error e) {
        err = e;
    }
    return;
}



public function cleanupOTP () (error err) {
    endpoint<sql:ClientConnector> ep {
        create sql:ClientConnector(sql:MYSQL, "192.168.48.209", 3306, "Bank", "root", "root", {maximumPoolSize:5});
    }
    sql:Parameter[] parameters = [];

    Time time = currentTime();
    Time tmSub = time.subtractDuration(0, 0, 1, 0, 0, 0, 0);
    println("After subtract duration: " + tmSub.toString());


    string query = "delete from OTP_Info where created_date < ?";

    try {
        sql:Parameter para1 = {sqlType:"timestamp", value:tmSub, direction:0};
        parameters = [para1];
        int dt = ep.update(query, parameters);
        println(dt);
        ep.close();

    }
    catch (error e) {
        e = {msg:"Cleanup error"};
        err = e;
    }

    return;
}


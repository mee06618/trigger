/**
 * Created by i2max-JaeyeonLee on 2022-06-29.
 */
// 필드 채워진걸로 점수(미완) web에서  받았을때 받은 데이터수로 점수 account생성시 확인 --새로 생성될때만

// 기업규모로 점수(미완) account의 Annual Revenue 이용 account생성시 확인 --새로 생성될때만 -완-
// 회사직원 수(미완) account의 NumberOfEmployees 이용 account생성시 확인 --새로 생성될때만 -완-

// lead 숫자 기준 하나당 5점 최대 20점 account에 score핃드 추가 lead생성시 확인 --lead생성시마다 -완-
// afterupdate 만들어야 될듯 edit햇을때

//case 삭제
public with sharing class LeadTriggerHandler extends TriggerHandler {




    Map<Id,Lead> LeadFields = new Map<Id,Lead>();









    public override void beforeInsert() {


        List<Account> existingAccounts = new List<Account>();

        for(Account temp :  [SELECT Name, Score__c FROM Account WHERE Name = :LeadFields.keySet()])
       {
                existingAccounts.add(temp);
       }


        updateLeadScore(existingAccounts); //lead 생성시 lead 점수 변환








        //기존의 같은 이름의 lead생성시 다른 정보 입력시 나머지 업데이트
        Map<Id,Lead> compareLead =new Map<Id,Lead>([SELECT Name,Id FROM Lead Where Id = :LeadFields.keySet()]);
        List<Lead> updateLead = new List<Lead>();
        Boolean isEqual = false;
        for(Lead newLead : LeadFields.values()){
            if(compareLead.containsKey(newLead.Id))
            {
                //중복

                isEqual=true;
                updateLead.add(newLead);
            }


        }
        //if(isEqual)
            //update updateLead;


    }
    public override void afterInsert() {

        //입력받은 값의 점수총합이 60이 넘어가면 Convert

        Database.LeadConvert[] converts = new Database.LeadConvert[0];


        for (Lead lead : LeadFields.values()) {

            if (lead.score__c >= 60) {


                if (lead.isConverted == false) //to prevent recursion
                {

                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(lead.Id);

                    lc.setContactId(lead.Id);
                    lc.setAccountId(lead.Id);
                    lc.convertedStatus = 'Closed - Converted';

                    lc.setDoNotCreateOpportunity(false);
                    converts.add(lc);

                }

                List<Lead> notConverted = [SELECT Id FROM Lead WHERE IsConverted=FALSE AND LastName=:lead.LastName and Company=:lead.Company AND ProductInterest__c =:lead.ProductInterest__c];

                for(Lead temp :notConverted){
                    System.debug(temp);
                  temp.Status='Closed - Not Converted';
                  update temp;
                }
            }


        }
        List<Database.LeadConvertResult> oppResult =  Database.convertLead(converts);

        for(Database.LeadConvertResult convert: oppResult) {

            Opportunity temp = [SELECT Name FROM Opportunity WHERE Id = :convert.opportunityId];
            Lead lead = [SELECT score__c FROM Lead WHERE Id =:convert.leadId];
            temp.score__c = lead.score__c;
            update temp;

            //last name first name, company,email,Phone

        }

    }
    public override  void beforeUpdate() {

//        Lead upserts = new Lead();
//        List<Account> existingAccounts = new List<Account>();
//
//        for(Account temp :  [SELECT Name, Score__c FROM Account WHERE Name = :LeadFields.keySet()])
//        {
//            existingAccounts.add(temp);
//        }
//
//        updateLeadScore(existingAccounts);
//        Database.LeadConvert[] converts = new Database.LeadConvert[0];
//        for (lead l : LeadFields.values()) {
//            if (l.score__c >= 60) {
//                if (l.isConverted == false) {
//                    Database.LeadConvert lc = new Database.LeadConvert();
//
//                    lc.setContactId(l.Id);
//                    lc.setAccountId(l.Id);
//
//                    lc.convertedStatus = 'Closed - Converted';
//
//                    lc.setDoNotCreateOpportunity(false);
//                    converts.add(lc);
//
//                }
//            }
//        }
//        Database.convertLead(converts);
       // List<Database.LeadConvertResult> oppResult =  Database.convertLead(converts);


//        for(Database.LeadConvertResult convert: oppResult) {
//            System.debug(convert);
//            Opportunity temp = [SELECT Name FROM Opportunity WHERE Id = :convert.opportunityId];
//            Lead lead = [SELECT score__c FROM Lead WHERE Id =:convert.leadId];
//            temp.score__c = lead.score__c;
//            update temp;
//
//            //last name first name, company,email,Phone
//
//        }

    }


//    public static List<Lead> findContacts(List<Lead> newList) {
//        List<Lead> foundLead = new List<Lead>();
//        List<Datacloud.FindDuplicatesResult> results;
//        try {
//            results = Datacloud.FindDuplicates.findDuplicates(newList);
//        } catch (Exception ex) {
//            return null;
//        }
//
//
//        for (Integer i = 0; i < newList.size(); i++) {
//            Lead foundCon = null;
//            for (Datacloud.DuplicateResult dr : results[i].getDuplicateResults()) {
//                if (dr.matchResults.size() > 0 && dr.getMatchResults()[0].matchRecords.size() > 0) {
//                    foundCon = (Lead) dr.getMatchResults()[0].getMatchRecords()[0].getRecord();
//                    break;
//                }
//            }
//            foundLead.add(foundCon);
//        }
//
//        return foundLead;
//    }
    private void updateLeadScore(List<Account> existingAccounts) {
        Integer score=0;
        //account생성 생성시 account 있는지 확인 lead있는지 확인후 갯수에따른 점수 업데이트
        if (existingAccounts.isEmpty()) {
            //입력된 회사가 없을때 - 회사 최초 입력시
            for (Lead l : LeadFields.values()) {
                score=0;
                score += getEmployeesScore(l.NumberOfEmployees);  //직원수에 따라 점수추가
                score += getRevenueScore((Integer) l.AnnualRevenue); //수입에 따라 점수추가
                score += getNumberOfFullfill(); //정보 채워진 정도에 따라 점수추가
                l.score__c=score;


            }


        } else { //이미 있는 회사

            List<Lead> LeadNum = [SELECT Id,score__c FROM Lead ];
            for (Lead l : LeadFields.values()) {



                    if (LeadNum.size() < 5) score = 5*LeadNum.size(); //lead의 개수가 5개 미만이면 각개수 마다 점수5점
                    else score = 20;
                    score += getEmployeesScore(l.NumberOfEmployees);  //직원수에 따라 점수추가
                    score += getRevenueScore((Integer) l.AnnualRevenue); //수입에 따라 점수추가
                    score += getNumberOfFullfill();//정보 채워진 정도에 따라 점수추가



                    l.score__c=score;
                    System.debug('점 : ' + score);




            }
        }
    }


    private Integer getRevenueScore(Integer revenue){
    Integer num =0;
        if(revenue>= 10000){
            num+=25;
        }
        else if(revenue>= 5000) {
            num+=20;
        }
        else if(revenue>= 1500) {
            num+=15;
        }
        else if(revenue>= 400) {
            num+=10;
        }

    return num;

    }


    private Integer getEmployeesScore(Integer employee){
    Integer num=0;
        if(employee>= 1000){
            num+=25;
        }
        else if(employee>= 700) {
            num+=20;
        }
        else if(employee>= 200) {
            num+=15;
        }
        else if(employee>= 50) {
            num+=10;
        }
    return num;

    }

    private Integer getNumberOfFullfill(){
        Integer num=0;
        for(lead lead : LeadFields.values()){
            if(lead.FirstName!=null)num++;
            if(lead.Title!=null)num++;
            if(lead.Industry!=null)num++;
            if(lead.AnnualRevenue!=null)num++;
            if(lead.Phone!=null)num++;
            if(lead.MobilePhone!=null)num++;
            if(lead.Email!=null)num++;
            if(lead.NumberOfEmployees!=null)num++;
        }
        if(num==8) num=25;
        else if(num>=5) num=20;
        else if(num>=3) num=15;
        else num=10;


        return num;
    }



}
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

    Integer updatedScore=0;
   public LeadTriggerHandler(){
        List<Lead> lists=Trigger.New;
        for(Lead lead : lists){
            LeadFields.put(lead.Id,lead);

        }


   }






    public override void beforeInsert() {
    if(Trigger.isInsert && trigger.isBefore ){
            List<Account> existingAccountsInsert = new List<Account>();
            for(Account temp :  [SELECT Name, Score__c FROM Account WHERE Id = :LeadFields.keySet()])
            {
                existingAccountsInsert.add(temp);

            }

            System.debug(existingAccountsInsert);
            updateLeadScore(existingAccountsInsert); //lead 생성시 lead 점수 변환



}
    }
    public override void afterInsert() {
    try {//2번실행되서 2번째는 null값이 들어가 error넘기고 실행하기위해
        //입력받은 값의 점수총합이 60이 넘어가면 Convert
        if (Trigger.isInsert && trigger.isAfter) {
            System.debug('삽입');
            Database.LeadConvert[] converts = new Database.LeadConvert[0];


            for (Lead lead : LeadFields.values()) {

                Account isDup = new Account();
                if (lead.score__c >= 60) {


                    if (lead.isConverted == false) //to prevent recursion
                    {

                        isDup = duplicate(lead.Company);


                        Database.LeadConvert lc = new Database.LeadConvert();
                        lc.setLeadId(lead.Id);

                        lc.setContactId(lead.Id);
                        if (isDup == null) {
                            lc.setAccountId(lead.Id);
                        } else {

                            lc.setAccountId(isDup.Id);
                        }
                        lc.convertedStatus = 'Closed - Converted';
                        System.debug(lc);
                        lc.setDoNotCreateOpportunity(false);
                        converts.add(lc);

                    }


                    //convert시 같은lead들 cancel
                    List<Lead> notConverted = [SELECT Id,Status FROM Lead WHERE IsConverted = FALSE AND LastName = :lead.LastName and Company = :lead.Company AND Status != 'Closed - Converted'];

                    for (Lead temp : notConverted) {

                        temp.Status = 'Cancel';

                        update temp;
                    }


//                    //기존의 같은 이름의 lead생성시 다른 정보 입력시 나머지 업데이트
//                    Map<Id, Lead> compareLead = new Map<Id, Lead>([SELECT Name, Id FROM Lead Where Id = :LeadFields.keySet()]);
//                    List<Lead> updateLead = new List<Lead>();
//                    Boolean isEqual = false;
//                    for (Lead newLead : LeadFields.values()) {
//                        if (compareLead.containsKey(newLead.Id)) {
//                            //중복
//
//                            isEqual = true;
//                            updateLead.add(newLead);
//                        }
//
//
//                    }


                    if (isDup != null) {
                        Account updateaAccount = [SELECT AnnualRevenue, NumberOfEmployees FROM Account WHERE Id = :isDup.Id limit 1];
                        System.debug('lead : '+lead );
                        updateaAccount.AnnualRevenue = lead.AnnualRevenue;
                        updateaAccount.NumberOfEmployees = lead.NumberOfEmployees;
                        System.debug('변환 account : '+updateaAccount );
                        System.debug('account 업데이트');
                    }

                }
                List<Database.LeadConvertResult> oppResult = Database.convertLead(converts);

                for (Database.LeadConvertResult convert : oppResult) {

                    Opportunity temp = [SELECT Name, score__c FROM Opportunity WHERE Id = :convert.opportunityId];
                    Lead tempLead = [SELECT score__c FROM Lead WHERE Id = :convert.leadId];
                    temp.score__c = tempLead.score__c;
                    update temp;

                }


            }
        }
    }catch(Exception e){
        System.debug(e);
    }
        HelperClass.flag=false;
}
    public override  void beforeUpdate() {
//        if (Trigger.isUpdate && Trigger.isBefore ) {
//            System.debug('점수변경');
//
//                Account isDup = new Account();
//                List<Account> existingAccountsUpdate = new List<Account>();
//                Lead tem = (Lead) LeadFields.values();
//                for (Account temp : [SELECT Name, Score__c FROM Account WHERE Name = :tem.Company]) {
//                    existingAccountsUpdate.add(temp);
//
//
//                }
//                System.debug('회사 : ' + existingAccountsUpdate);
//                updateLeadScore(existingAccountsUpdate);
//
//
//            }

    }


    public override void afterUpdate() {
//        try {
//            if (Trigger.isUpdate && Trigger.isAfter ) {
//                System.debug('업데이트');
//                Database.LeadConvert[] converts = new Database.LeadConvert[0];
//
//                for (lead l : LeadFields.values()) {
//                    System.debug('중복회사' + l.Company);
//                    Account isDup = new Account();
//                    if (l.score__c >= 60) {
//
//                        if (l.isConverted == false) {
//
//
//                            isDup = duplicate(l.Company);
//
//                            Database.LeadConvert lc = new Database.LeadConvert();
//                            lc.setLeadId(l.Id);
//                            lc.setContactId(l.Id);
//                            if (isDup == null) {
//                                lc.setAccountId(l.Id);
//                            } else {
//
//                                lc.setAccountId(isDup.Id);
//                            }
//
//
//                            lc.convertedStatus = 'Closed - Converted';
//
//                            lc.setDoNotCreateOpportunity(false);
//                            converts.add(lc);
//
//                        }
//
//
//                        if (isDup != null) {
//                            Account updateaAccount = [SELECT AnnualRevenue, NumberOfEmployees FROM Account WHERE Id = :isDup.Id limit 1];
//                            System.debug('lead : '+l );
//                            updateaAccount.AnnualRevenue = l.AnnualRevenue;
//                            updateaAccount.NumberOfEmployees = l.NumberOfEmployees;
//                            System.debug('변환 account : '+updateaAccount );
//                            System.debug('account 업데이트');
//                            update updateaAccount;
//                        }
//
//                        //  Database.convertLead(converts);
//
//                        List<Database.LeadConvertResult> oppResult = Database.convertLead(converts);
//
//                        System.debug('result : ' + oppResult);
//                        for (Database.LeadConvertResult convert : oppResult) {
//
//                            Opportunity temp = [SELECT Name, score__c FROM Opportunity WHERE Id = :convert.opportunityId];
//
//                            Lead lead = [SELECT score__c FROM Lead WHERE Id = :convert.leadId];
//
//
//                            temp.score__c = lead.score__c;
//                            System.debug('opp : ' + temp);
//                            upsert temp;
//                        }
//                        List<Lead> notConverted = [SELECT Id FROM Lead WHERE IsConverted = FALSE AND LastName = :l.LastName and Company = :l.Company AND Status != 'Closed - Converted'];
//
//                        for (Lead temp : notConverted) {
//
//                            temp.Status = 'Cancel';
//
//                            update temp;
//                        }
//                    }
//
//                }
//
//
//            }
//        } catch (Exception e) {
//            System.debug('업데이트 오류 : ' + e);
//        }
//        HelperClass.flag=false;
    }

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

            System.debug('중복');
            for (Lead lead : LeadFields.values()) {

                List<Lead> LeadNum = [SELECT Id,score__c FROM Lead WHERE LastName=:lead.LastName and Company=:lead.Company AND Status!='Cancel'];
                    if(LeadNum.size()==1)score=0;
                    else if (LeadNum.size() < 5) score = 5*(LeadNum.size()-1); //lead의 개수가 5개 미만이면 각개수 마다 점수5점
                    else score = 20;
                    score += getEmployeesScore(lead.NumberOfEmployees);  //직원수에 따라 점수추가
                    score += getRevenueScore((Integer) lead.AnnualRevenue); //수입에 따라 점수추가
                    score += getNumberOfFullfill();//정보 채워진 정도에 따라 점수추가

                if(trigger.isUpdate) {
                    lead.score__c = score;

                }else{
                    updatedScore=score;
                }






            }
        }
        System.debug('입력된 점수 '+score);
    }

    private Account duplicate(String inputCompany) {

        //List<Lead> duplicateRecords = new List<Lead>();
        List<SObject> accounts = new List<SObject>();
        Account account = new Account();
        account.Name=inputCompany;


        accounts.add(account);

        Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(accounts);
        System.debug('조회 : '+results);
        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {

                        Account matchingAccount = (Account)matchRecord.getRecord();
                        System.debug('중복 ' +matchingAccount);
                        return matchingAccount;
                    }
                }
            }
        }







        return null;



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
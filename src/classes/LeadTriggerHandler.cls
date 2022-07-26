/**
 * Created by i2max-JaeyeonLee on 2022-06-29.
 */
// 필드 채워진걸로 점수(미완) web에서  받았을때 받은 데이터수로 점수 account생성시 확인 --새로 생성될때만

// 기업규모로 점수(미완) account의 Annual Revenue 이용 account생성시 확인 --새로 생성될때만 -완-
// 회사직원 수(미완) account의 NumberOfEmployees 이용 account생성시 확인 --새로 생성될때만 -완-

// lead 숫자 기준 하나당 5점 최대 20점 account에 score핃드 추가 lead생성시 확인 --lead생성시마다 -완-
// afterupdate 만들어야 될듯 edit햇을때

//case 삭제
////////////////// 벌크부분 수정 ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ

public with sharing class LeadTriggerHandler extends TriggerHandler {

    Map<Id,Lead> LeadFields = new Map<Id,Lead>();

   Static String reliability;
   public LeadTriggerHandler(){
        List<Lead> lists=Trigger.New;
        for(Lead lead : lists){
            LeadFields.put(lead.Id,lead);

        }

   }






    public override void beforeInsert() {
   if(Trigger.isInsert && trigger.isBefore){
       System.debug('before : '+Trigger.new);

        for(Lead lead : (List<Lead>)Trigger.new)
        {

            updateLeadScore(lead);

        }



    }

    }
    public override void afterInsert() {
        if(Trigger.isInsert && trigger.isAfter) {
            System.debug('after insert : ' + (List<Lead>) Trigger.new);
            try {
                Account isDup = new Account();
                List<Score__c> scoresss = new List<Score__c>();
                list<Lead> LeadsToConvert = new list<Lead>();

                for (Lead myLead : (List<Lead>) Trigger.new) {
                    if (!myLead.isConverted && myLead.score__c >= 60) {
                        System.debug('통과 ' + myLead.LastName);
                        LeadsToConvert.add(myLead);
                        isDup = duplicate(myLead.Company);

                        Lead tempLead = new Lead(Id=myLead.Id);
                            if(myLead.Status!= 'Closed - Converted')
                                tempLead.Status = 'Cancel';


                        if (isDup != null) {
                            Account updateaAccount = [SELECT AnnualRevenue, NumberOfEmployees FROM Account WHERE Id = :isDup.Id limit 1];
                            updateaAccount.AnnualRevenue = myLead.AnnualRevenue;
                            updateaAccount.NumberOfEmployees = myLead.NumberOfEmployees;
                            System.debug('변환 account : ' + updateaAccount);
                            System.debug('account 업데이트');
                            ///     update updateaAccount; for밖에다

                        }
                    }
                }

                list<Database.LeadConvert> converts = new list<Database.LeadConvert>();
                for (Lead myLead : LeadsToConvert) {
                    Database.LeadConvert lc = new database.LeadConvert();
                    lc.setLeadId(myLead.Id);
                    lc.setContactId(myLead.Id);
                    if (isDup == null) {
                        lc.setAccountId(myLead.Id);
                    } else {

                        lc.setAccountId(isDup.Id);
                    }


                    lc.convertedStatus = 'Closed - Converted';
                    converts.add(lc);



                    Score__c scores = new Score__c();

                    scores.LeadName__c = myLead.FirstName + myLead.LastName;
                    scores.Company__c = myLead.Company;
                    scores.AnnualRevenue__c = myLead.AnnualRevenue;
                    scores.Score__c = myLead.score__c;
                    scores.NumberOfEmployees__c = myLead.NumberOfEmployees;
                    scores.reliability__c = reliability;
                    scoresss.add(scores);
                }

                if (!converts.isEmpty()) {
                    Database.LeadConvertResult[] lcrList = Database.convertLead(converts, false);


                }


            } catch (Exception e) {
                System.debug('업데이트 오류 : ' + e);
            }

        }

}
    public override  void beforeUpdate() {
        if (Trigger.isUpdate && Trigger.isBefore ) {

            for(Lead lead :  (List<Lead>)Trigger.new)
            {

                updateLeadScore(lead);

            }






            }

    }


    public override void afterUpdate() {

        if (Trigger.isUpdate && Trigger.isAfter ) {
            try {
                Account isDup = new Account();
                List<Score__c> scoresss = new List<Score__c>();
                list<Lead> LeadsToConvert = new list<Lead>();

                for (Lead myLead : (List<Lead>) Trigger.new) {
                    if (!myLead.isConverted && myLead.score__c >= 60) {
                        System.debug('통과 ' + myLead.LastName);
                        LeadsToConvert.add(myLead);
                        isDup = duplicate(myLead.Company);


                        if(myLead.Status!= 'Closed - Converted')
                            myLead.Status = 'Cancel';


                        if (isDup != null) {
                            Account updateaAccount = [SELECT AnnualRevenue, NumberOfEmployees FROM Account WHERE Id = :isDup.Id limit 1];
                            updateaAccount.AnnualRevenue = myLead.AnnualRevenue;
                            updateaAccount.NumberOfEmployees = myLead.NumberOfEmployees;
                            System.debug('변환 account : ' + updateaAccount);
                            System.debug('account 업데이트');
                            ///     update updateaAccount; for밖에다

                        }
                    }
                }

                list<Database.LeadConvert> converts = new list<Database.LeadConvert>();
                for (Lead myLead : LeadsToConvert) {
                    Database.LeadConvert lc = new database.LeadConvert();
                    lc.setLeadId(myLead.Id);
                    lc.setContactId(myLead.Id);
                    if (isDup == null) {
                        lc.setAccountId(myLead.Id);
                    } else {

                        lc.setAccountId(isDup.Id);
                    }


                    lc.convertedStatus = 'Closed - Converted';
                    converts.add(lc);



                    Score__c scores = new Score__c();

                    scores.LeadName__c = myLead.FirstName + myLead.LastName;
                    scores.Company__c = myLead.Company;
                    scores.AnnualRevenue__c = myLead.AnnualRevenue;
                    scores.Score__c = myLead.score__c;
                    scores.NumberOfEmployees__c = myLead.NumberOfEmployees;
                    scores.reliability__c = reliability;
                    scoresss.add(scores);
                }

                if (!converts.isEmpty()) {
                    Database.LeadConvertResult[] lcrList = Database.convertLead(converts, false);


                }



            } catch (Exception e) {
                System.debug('업데이트 오류 : ' + e);
            }
        }
    }

    private void updateLeadScore(Lead newlead) {
        Integer score=0;
        //account생성 생성시 account 있는지 확인 lead있는지 확인후 갯수에따른 점수 업데이트

        List<Account> acc =[SELECT Id FROM Account  WHERE Id =:newlead.Id];
        if (acc.size()<1) {
            System.debug('신규회사');
        //입력된 회사가 없을때 - 회사 최초 입력시


            score = 0;
            score += getEmployeesScore(newLead.NumberOfEmployees);  //직원수에 따라 점수추가
            score += getRevenueScore((Integer) newLead.AnnualRevenue); //수입에 따라 점수추가
            score += getNumberOfFullfill(); //정보 채워진 정도에 따라 점수추가
            newLead.score__c = score;



    } else { //이미 있는 회사

        System.debug('중복');

                List<Lead> LeadNum = [SELECT Id, score__c FROM Lead WHERE LastName = :newlead.LastName and Company = :newlead.Company AND Status != 'Cancel'];
                if (LeadNum.size() == 1)score = 0;
                else if (LeadNum.size() < 5) score = 5 * (LeadNum.size() - 1); //lead의 개수가 5개 미만이면 각개수 마다 점수5점
                else score = 20;
                score += getEmployeesScore(newlead.NumberOfEmployees);  //직원수에 따라 점수추가
                score += getRevenueScore((Integer) newlead.AnnualRevenue); //수입에 따라 점수추가
                score += getNumberOfFullfill();//정보 채워진 정도에 따라 점수추가

            newlead.score__c = score;



}
        }




    private Account duplicate(String inputCompany) {

        //List<Lead> duplicateRecords = new List<Lead>();
        List<SObject> accounts = new List<SObject>();
        Account account = new Account();
        account.Name=inputCompany;


        accounts.add(account);


        Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(accounts);

        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {

                        Account matchingAccount = (Account)matchRecord.getRecord();

                        if(matchingAccount !=null)
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
        if(num==8) {num=25;
            reliability='높음';}
        else if(num>=5) {num=20;
            reliability='보통';}
        else if(num>=3) {num=15;
            reliability='낮음';}
        else {num=10;
            reliability='없음';}


        return num;
    }



}
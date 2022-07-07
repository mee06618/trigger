/**
 * Created by i2max-JaeyeonLee on 2022-06-29.
 */
// 필드 채워진걸로 점수(미완) web에서  받았을때 받은 데이터수로 점수 account생성시 확인 --새로 생성될때만

// 기업규모로 점수(미완) account의 Annual Revenue 이용 account생성시 확인 --새로 생성될때만 -완-
// 회사직원 수(미완) account의 NumberOfEmployees 이용 account생성시 확인 --새로 생성될때만 -완-

// lead 숫자 기준 하나당 5점 최대 20점 account에 score핃드 추가 lead생성시 확인 --lead생성시마다 -완-

public with sharing class LeadTriggerHandler extends TriggerHandler {
   List<Lead> newLeads;
    static Set<Id> leadIds = new Set<Id>();
   static Integer num=0;
    static Integer score=0;
    set<string> newNameSet = new set<string>();
    set<string> dbNameSet = new set<string>();
    Set<String> companyNames = New Set<String>();
    Set<String> lastNames = New Set<String>();
    Map<String,ID> accountNamesId=new Map<String,ID>();
    public LeadTriggerHandler(){
        newLeads=(List<Lead>) Trigger.new;
    }
    public override void beforeInsert() {




        for(Lead l : newLeads){
            companyNames.add(l.Company);
            lastNames.add(l.LastName);
            leadIds.add(l.Id);
            newNameSet.add(l.LastName);
        }
      //  for(Lead dbLead :[select id, LastName from lead where LastName =:newLead.LastName]){

        //dbNameSet.add(dbLead.LastName);



       // }

        List<Case> newCases = new List<Case>();
        List<Account> newAccount = new List<Account>();
        List<Account> existingAccounts = [SELECT Name,Score__c FROM Account WHERE Name Like :companyNames];
        List<Lead> LeadNum = [SELECT Name FROM Lead WHERE Company Like :companyNames];

        Integer leadsNum = leadNum.size();

        //account생성 생성시 account 있는지 확인 lead있는지 확인후 갯수에따른 점수 업데이트

        // Insert or update the order_batch__c


        if(existingAccounts.isEmpty()){

            for(Lead l : newLeads){
                Account a = new Account();
                getEmployeesScore(l.NumberOfEmployees);
                getRevenueScore((Integer)  l.AnnualRevenue);
                a.Score__c=0;
                a.Score__c+=num;
                score=(Integer) a.Score__c;
                System.debug('새로 생성됨 현재 점수 : '+a.Score__c);

            }



        }
        else{
            List<Account> accNum= [SELECT Name,Score__c FROM Account WHERE Name Like :companyNames];
            for(Account a : existingAccounts){

                accountNamesId.put(a.Name,a.Id);
                if(accNum.size()<5) num=5;
                else num=0;


                a.Score__c=accNum[0].Score__c;

                a.Score__c+=num;
                score=(Integer) a.Score__c;
                System.debug('추가되서 변한 점수 : '+score  );
               // newAccount.add(a);
            }

           // update newAccount;
        }
        score+=getNumberOfFullfill(newLeads);
        System.debug('last ' +score);
        Lead upserts = new Lead();
        try {
            for (Lead ob : [
                    select id, LastName
                    from Lead
                    where LastName LIKE :lastNames
                    LIMIT 1
            ]) {
                upserts = ob;
            }
            for (Lead b : newLeads) {
                // Get record to update


                upserts.Company = b.Company;
                upserts.NumberOfEmployees=b.NumberOfEmployees;
                upserts.AnnualRevenue=b.AnnualRevenue;
            }

            update upserts;

        }catch(Exception e){

        }


       //

    }

    public override void afterInsert(){

        if(score>=60){
            List<Case> newCases = new List<Case>();
            List<Account> newAccount = new List<Account>();
            List<Account> existingAccounts = [SELECT Name FROM Account WHERE Name Like :companyNames];
            List<Lead> LeadNum = [SELECT Name FROM Lead WHERE Company Like :companyNames];
            for (Lead lead : newLeads) {

                if (lead.isConverted== false) //to prevent recursion
                {


                    Opportunity opp = new Opportunity();
                    if(lead.Title!=null)
                        opp.Name = lead.Title;
                    else
                            opp.Name=lead.Company+' 기회';

                    Date myDate = Date.today();
                    myDate= myDate.addYears(1);
                    opp.CloseDate = myDate;

                    opp.StageName='Prospecting';


                    insert opp;




                for(Lead l : newLeads){
                    if (accountNamesId.keySet().contains(l.Company)){
                        Case c = new Case ();
                        c.AccountId = accountNamesId.get(l.Company);
                        c.Subject='이미 있는 '+l.Company;
                        c.Status = '생성됨';
                        newCases.add(c);
                        //기존에 있으니 추가점수
                    }
                    else {
                        Case c = new Case ();
                        c.AccountId = accountNamesId.get(l.Company);
                        c.Subject='신규 '+l.Company;
                        c.Status = '처음생성됨';
                        newCases.add(c);
                    }
                    insert newCases;
                }

                    List<Account> duplicateAccounts = [SELECT Id, Name
                    FROM Account
                    WHERE Name LIKE :lead.Company];

                    if(duplicateAccounts.size()==0){

                        for(Lead l : newLeads){
                            Account a = new Account();
                            num=0;
                            getEmployeesScore(l.NumberOfEmployees);
                            getRevenueScore((Integer)  l.AnnualRevenue);
                            a.Score__c=num;
                            a.Name=l.Company;
                            newAccount.add(a);
                        }
                        System.debug('최초 account 생성');
                         insert newAccount;
                    }
                    else{
                        List<Account> temp = new List<Account>();
                        for(Account a : existingAccounts){
                            accountNamesId.put(a.Name,a.Id);
                            a.Score__c=score;
                            temp.add(a);
                            System.debug('동일 account 생성');

                        }
                        update temp;


                    }
                    Contact con = new Contact();
                    con.LastName=lead.LastName;
                    insert con;
                  //  Lead newLead= [SELECT Id FROM Lead WHERE Id =:lead.Id];
                  //  newLead.Status ='Closed - Converted';
                  //  update newLead;

                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(lead.Id);

                    lc.convertedStatus = 'Closed - Converted';


                    lc.setDoNotCreateOpportunity(true);
                    Database.LeadConvertResult lcr = Database.convertLead(lc);
                    System.debug(lcr.isSuccess());


                }


            }
        }


    }


    private void getRevenueScore(Integer revenue){

            if(revenue>= 10000){
                num+=30;
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



        }


    private void getEmployeesScore(Integer employee){

        if(employee>= 1000){
            num+=30;
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


        }

    private Integer getNumberOfFullfill(List<Lead> leads){
        Integer score=0;
        for(lead lead : leads){
            if(lead.FirstName!=null)score++;
            if(lead.Title!=null)score++;
            if(lead.Industry!=null)score++;
            if(lead.AnnualRevenue!=null)score++;
            if(lead.Phone!=null)score++;
            if(lead.MobilePhone!=null)score++;
            if(lead.Email!=null)score++;
            if(lead.NumberOfEmployees!=null)score++;
        }
        if(score==8) score=25;
        else if(score>=5) score=20;
        else if(score>=3) score=15;
        else score=10;


    return score;
    }


    }

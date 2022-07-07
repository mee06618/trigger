/**
 * Created by i2max-JaeyeonLee on 2022-06-29.
 */
// 필드 채워진걸로 점수(미완) web에서  받았을때 받은 데이터수로 점수 account생성시 확인 --새로 생성될때만

// 기업규모로 점수(미완) account의 Annual Revenue 이용 account생성시 확인 --새로 생성될때만 -완-
// 회사직원 수(미완) account의 NumberOfEmployees 이용 account생성시 확인 --새로 생성될때만 -완-

// lead 숫자 기준 하나당 5점 최대 20점 account에 score핃드 추가 lead생성시 확인 --lead생성시마다 -완-
// afterupdate 만들어야 될듯 edit햇을때
public with sharing class LeadTriggerHandler extends TriggerHandler {
    List<Lead> newLeads;
    static Integer num=0;
    static Integer score=0;


    Set<String> companyNames = New Set<String>();
    Set<String> lastNames = New Set<String>();
    Map<String,ID> accountNamesId=new Map<String,ID>();


    public LeadTriggerHandler(){
        newLeads=(List<Lead>) Trigger.new;
    }




    public override void beforeInsert() {


        for (Lead l : newLeads) {
            companyNames.add(l.Company);
            lastNames.add(l.LastName);


        }


        List<Account> existingAccounts = [SELECT Name, Score__c FROM Account WHERE Name Like :companyNames];


        //account생성 생성시 account 있는지 확인 lead있는지 확인후 갯수에따른 점수 업데이트
        if (existingAccounts.isEmpty()) {
            //입력된 회사가 없을때 - 회사 최초 입력시
            for (Lead l : newLeads) {
                Account a = new Account();
                getEmployeesScore(l.NumberOfEmployees);  //직원수에 따라 점수추가
                getRevenueScore((Integer) l.AnnualRevenue); //수입에 따라 점수추가
                a.Score__c = 0;
                a.Score__c += num;
                score = (Integer) a.Score__c; //직원수 수입 점수 추가 됨
                System.debug('새로 생성됨 현재 점수 : ' + a.Score__c);

            }

            //insert 자동


        } else { //이미 있는 회사
            List<Account> accNum = [SELECT Name, Score__c FROM Account WHERE Name Like :companyNames];
            for (Account a : existingAccounts) {

                accountNamesId.put(a.Name, a.Id);
                if (accNum.size() < 5) num = 5; //lead의 개수가 5개 미만이면 각개수 마다 점수5점
                else num = 0;

//                getEmployeesScore(l.NumberOfEmployees);  //직원수에 따라 점수추가
//                getRevenueScore((Integer)  l.AnnualRevenue); //수입에 따라 점수추가
                //처음 입력됬을때 회사 수입 입력되서 생략

                a.Score__c = accNum[0].Score__c;

                a.Score__c += num;
                score = (Integer) a.Score__c;
                System.debug('추가되서 변한 점수 : ' + score);

            }


        }


        score += getNumberOfFullfill(newLeads); //lead입력시 정보의 개수에따라 점수 추가
        System.debug('last ' + score);


        //기존의 같은 이름의 lead생성시 다른 정보 입력시 나머지 업데이트
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

                upserts.Company = b.Company;
                upserts.NumberOfEmployees = b.NumberOfEmployees;
                upserts.AnnualRevenue = b.AnnualRevenue;
            }

            update upserts;

        } catch (Exception e) {

        }

        if (score >= 60) { //점수 60점 이상일때 account contact case 생성
            List<Case> newCases = new List<Case>();
            List<Account> newAccount = new List<Account>();

            for (Lead lead : newLeads) {

                if (lead.isConverted == false) //convert가 안되있으면
                {


                    Opportunity opp = new Opportunity();
                    if (lead.Title != null)
                        opp.Name = lead.Title;
                    else
                            opp.Name = lead.Company + ' 기회';

                    Date myDate = Date.today();
                    myDate = myDate.addYears(1);
                    opp.CloseDate = myDate;

                    opp.StageName = 'Prospecting';


                    insert opp;


                    for (Lead l : newLeads) {
                        if (accountNamesId.keySet().contains(l.Company)) {
                            Case c = new Case ();
                            c.AccountId = accountNamesId.get(l.Company);
                            c.Subject = '이미 있는 ' + l.Company;
                            c.Status = '생성됨';
                            newCases.add(c);
                            //기존에 있으니 추가점수
                        } else {
                            Case c = new Case ();
                            c.AccountId = accountNamesId.get(l.Company);
                            c.Subject = '신규 ' + l.Company;
                            c.Status = '처음생성됨';
                            newCases.add(c);
                        }
                        insert newCases;
                    }

                    List<Account> duplicateAccounts = [
                            SELECT Id, Name
                            FROM Account
                            WHERE Name LIKE :lead.Company
                    ];

                    if (duplicateAccounts.size() == 0) { //Account에 같은 이름을 가진 회사가없으면 생성 있으면 정보 업데이트

                        for (Lead l : newLeads) {
                            Account a = new Account();

                            getEmployeesScore(l.NumberOfEmployees);
                            getRevenueScore((Integer) l.AnnualRevenue);
                            a.Score__c = score;
                            a.Name = l.Company;
                            newAccount.add(a);
                        }
                        System.debug('최초 account 생성');
                       // insert newAccount;
                    } else {
                        List<Account> temp = new List<Account>();
                        for (Account a : existingAccounts) {
                            accountNamesId.put(a.Name, a.Id);
                            a.Score__c = score;
                            temp.add(a);
                            System.debug('동일 account 생성');

                        }
                        update temp;


                    }
                    Contact con = new Contact();
                    con.LastName = lead.LastName;
                    insert con;

                }


            }
        }
    }
    public override void afterInsert() {
        if (score >= 60) { //데이터 입력후 점수가 60점이상이면 lead convert


            for (Lead lead : newLeads) {

                if (lead.isConverted == false && score>=60) //to prevent recursion
                {

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
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







    public override void beforeInsert() {
        if (Trigger.isInsert && trigger.isBefore) {
            updateLeadScore();
        }
    }
    public override void afterInsert() {
        if (Trigger.isInsert && trigger.isAfter) {
            LeadConvert();
        }
    }
    public override void beforeUpdate() {
        if (Trigger.isUpdate && Trigger.isBefore) {
            updateLeadScore();
        }
    }


    public override void afterUpdate() {
        if (Trigger.isUpdate && Trigger.isAfter) {
                LeadConvert();
        }
    }

    private void updateLeadScore() {
        Integer score = 0;
        Map<String,Lead> leadCompany = new Map<String,Lead>();
        for(Lead l : (List<Lead>) Trigger.new)
            leadCompany.put(l.Company,l);
        for(Lead newLeads :leadCompany.values()) {
            List<Lead> leadex = [SELECT Id, Company FROM Lead WHERE Company = :newLeads.Company and Status!='Cancel' and Status!='Closed - Converted'];
            if (leadex.size() == 0) {


                score = 0;
                score += getEmployeesScore(newLeads.NumberOfEmployees);  //직원수에 따라 점수추가
                score += getRevenueScore((Integer) newLeads.AnnualRevenue); //수입에 따라 점수추가
                score += getNumberOfFullfill(); //정보 채워진 정도에 따라 점수추가
                newLeads.score__c = score;

            } else { //이미 있는 회사


                if(leadex.size() ==null) score=0;
                else if(leadex.size() < 5) score = 5 * (leadex.size()); //lead의 개수가 5개 미만이면 각개수 마다 점수5점
                else score = 20;


                score += getEmployeesScore(newLeads.NumberOfEmployees);  //직원수에 따라 점수추가
                score += getRevenueScore((Integer) newLeads.AnnualRevenue); //수입에 따라 점수추가
                score += getNumberOfFullfill(); //정보 채워진 정도에 따라 점수추가
                newLeads.score__c = score;


            }
        }
    }


    private void LeadConvert() {
        try {
            Account isDup = new Account();
            list<Lead> LeadsToConvert = new list<Lead>();
            Set<String> notConvertedLead = new Set<String>();
            Set<String> notConvertedLeadName = new Set<String>();
            for (Lead myLead : (List<Lead>) Trigger.new) {
                if (!myLead.isConverted && myLead.score__c >= 60) {
                    System.debug('통과 ' + myLead.LastName);
                    LeadsToConvert.add(myLead);
                    isDup = duplicate(myLead.Company);

                    notConvertedLead.add(myLead.Company);
                    notConvertedLeadName.add(myLead.LastName);

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
                    lc.setAccountId(myLead.Id); //lead id != account id
                } else {

                    lc.setAccountId(isDup.Id);
                }


                lc.convertedStatus = 'Closed - Converted';
                converts.add(lc);


            }



            List<Lead> tempLeads =new List<Lead>();
            if (!converts.isEmpty()) {
                Database.convertLead(converts, false);
                System.debug('com : ' + notConvertedLead +'name : '+notConvertedLeadName);
                for(Lead temp :[SELECT Status FROM Lead WHERE Company=:notConvertedLead AND LastName=:notConvertedLeadName
                AND Status !='Closed - Converted']) {
                    System.debug('temp' +temp);
                    Lead tempLead = new Lead();
                    tempLead.Id=temp.Id;
                    tempLead.Status = 'Cancel';
                    tempLead.score__c=0;
                    tempLeads.add(tempLead);
                }



            }
            update tempLeads;


        } catch (Exception e) {
            System.debug('업데이트 오류 : ' + e);
        }

    }
    private Account duplicate(String inputCompany) {

        //List<Lead> duplicateRecords = new List<Lead>();
        List<SObject> accounts = new List<SObject>();
        Account account = new Account();
        account.Name = inputCompany;


        accounts.add(account);


        Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(accounts);

        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {

                        Account matchingAccount = (Account) matchRecord.getRecord();

                        if (matchingAccount != null)
                            return matchingAccount;
                    }
                }
            }
        }


        return null;


    }

    private Integer getRevenueScore(Integer revenue) {
        Integer num = 0;
        if (revenue >= 10000) {
            num += 25;
        } else if (revenue >= 5000) {
            num += 20;
        } else if (revenue >= 1500) {
            num += 15;
        } else if (revenue >= 400) {
            num += 10;
        }

        return num;

    }


    private Integer getEmployeesScore(Integer employee) {
        Integer num = 0;
        if (employee >= 1000) {
            num += 25;
        } else if (employee >= 700) {
            num += 20;
        } else if (employee >= 200) {
            num += 15;
        } else if (employee >= 50) {
            num += 10;
        }
        return num;

    }

    private Integer getNumberOfFullfill() {
        Integer num = 0;
        for (lead lead : (List<Lead>) Trigger.new) {
            if (lead.FirstName != null)num++;
            if (lead.Title != null)num++;
            if (lead.Industry != null)num++;
            if (lead.AnnualRevenue != null)num++;
            if (lead.Phone != null)num++;
            if (lead.MobilePhone != null)num++;
            if (lead.Email != null)num++;

        }
        if (num == 8) {
            num = 25;

        } else if (num >= 5) {
            num = 20;

        } else if (num >= 3) {
            num = 15;

        } else {
            num = 10;

        }


        return num;
    }
}



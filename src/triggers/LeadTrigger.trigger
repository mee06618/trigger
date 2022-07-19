/**
 * Created by i2max-JaeyeonLee on 2022-06-29.
 */

trigger LeadTrigger on Lead (before insert,after insert,before update,after update) {
    new LeadTriggerHandler().run();
}
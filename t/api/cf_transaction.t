#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use RT::Test; use Test::More; 

plan tests => 14;

use_ok('RT');
use_ok('RT::Model::TransactionCollection');


my $q = RT::Model::Queue->new(current_user => RT->system_user);
my ($id,$msg) = $q->create( name => 'TxnCFTest'.$$);
ok($id,$msg);

my $cf = RT::Model::CustomField->new(current_user => RT->system_user);
($id,$msg) = $cf->create(name => 'Txnfreeform-'.$$, type => 'Freeform', MaxValues => '0', lookup_type => RT::Model::Transaction->custom_field_lookup_type );

ok($id,$msg);

($id,$msg) = $cf->add_to_object($q);

ok($id,$msg);


my $ticket = RT::Model::Ticket->new(current_user => RT->system_user);

my $transid;
($id,$transid, $msg) = $ticket->create(queue => $q->id,
                subject => 'TxnCF test',
            );
ok($id,$msg);

my $trans = RT::Model::Transaction->new(current_user => RT->system_user);
$trans->load($transid);

is($trans->object_id,$id);
is ($trans->object_type, 'RT::Model::Ticket');
is ($trans->type, 'Create');
my $txncfs = $trans->custom_fields;
is ($txncfs->count, 1, "We have one custom field");
my $txn_cf = $txncfs->first;
is ($txn_cf->id, $cf->id, "It's the right custom field");
my $values = $trans->custom_field_values($txn_cf->id);
is ($values->count, 0, "It has no values");

# Old API
my %cf_updates = ( 'CustomField-'.$cf->id => 'Testing');
$trans->update_custom_fields( ARGSRef => \%cf_updates);

 $values = $trans->custom_field_values($txn_cf->id);
is ($values->count, 1, "It has one value");

# New API

$trans->update_custom_fields( 'CustomField-'.$cf->id => 'Test two');
 $values = $trans->custom_field_values($txn_cf->id);
is ($values->count, 2, "it has two values");

# TODO ok(0, "Should updating custom field values remove old values?");

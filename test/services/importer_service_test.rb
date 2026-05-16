require "test_helper"

class ImporterServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @account = accounts(:one)
  end

  test "import_csv creates transactions from CSV" do
    csv = "date,description,amount,type\n2026-05-10,ImpCSVTest1,150.50,expense\n2026-05-11,ImpCSVTest2,5000.00,income\n"

    file = Tempfile.new(["test", ".csv"])
    file.write(csv)
    file.close

    assert_difference("Transaction.count", 2) do
      ImporterService.import(File.open(file.path), @user, @account, format: :csv)
    end

    tx1 = @user.transactions.find_by!(description: "ImpCSVTest1")
    assert_equal Date.new(2026, 5, 10), tx1.date
    assert_equal 15050, tx1.amount
    assert_equal "expense", tx1.transaction_type
    assert_equal @account, tx1.account

    tx2 = @user.transactions.find_by!(description: "ImpCSVTest2")
    assert_equal Date.new(2026, 5, 11), tx2.date
    assert_equal 500000, tx2.amount
    assert_equal "income", tx2.transaction_type
  ensure
    file&.close
    file&.unlink
  end

  test "import_csv skips duplicates" do
    @user.transactions.create!(
      account: @account, date: Date.new(2026, 5, 10),
      description: "ImpCSVTestDup", amount: 15050,
      transaction_type: "expense"
    )

    csv = "date,description,amount,type\n2026-05-10,ImpCSVTestDup,150.50,expense\n2026-05-11,ImpCSVTest3,5000.00,income\n"

    file = Tempfile.new(["test", ".csv"])
    file.write(csv)
    file.close

    assert_difference("Transaction.count", 1) do
      ImporterService.import(File.open(file.path), @user, @account, format: :csv)
    end
  ensure
    file&.close
    file&.unlink
  end

  test "auto_categorize uses CategorizationRule first" do
    rule = categorization_rules(:one)
    assert_equal rule.category, ImporterService.send(:auto_categorize, "MERCADO TESTE", @user)
  end

  test "auto_categorize falls back to CategorizationSuggestion" do
    suggestion = categorization_suggestions(:one)
    assert_equal suggestion.category, ImporterService.send(:auto_categorize, "UBER DO BRASIL", @user)
  end

  test "auto_categorize returns nil for unknown description" do
    assert_nil ImporterService.send(:auto_categorize, "DESCRICAO DESCONHECIDA XYZ", @user)
  end

  test "raises error for unsupported format" do
    file = Tempfile.new(["test", ".txt"])
    assert_raise(RuntimeError, "Formato não suportado: txt") do
      ImporterService.import(file, @user, @account, format: :txt)
    end
  ensure
    file&.close
    file&.unlink
  end

  test "import_ofx creates transactions from OFX file" do
    ofx_content = <<~OFX
      OFXHEADER:100
      DATA:OFXSGML
      VERSION:102
      SECURITY:NONE
      ENCODING:USASCII
      CHARSET:1252
      COMPRESSION:NONE
      OLDFILEUID:NONE
      NEWFILEUID:NONE

      <OFX>
        <SIGNONMSGSRSV1>
          <SONRS>
            <STATUS><CODE>0</CODE><SEVERITY>INFO</SEVERITY></STATUS>
            <DTSERVER>20260510120000</DTSERVER>
            <LANGUAGE>POR</LANGUAGE>
          </SONRS>
        </SIGNONMSGSRSV1>
        <BANKMSGSRSV1>
          <STMTTRNRS>
            <TRNUID>0</TRNUID>
            <STATUS><CODE>0</CODE><SEVERITY>INFO</SEVERITY></STATUS>
            <STMTRS>
              <CURDEF>BRL</CURDEF>
              <BANKACCTFROM>
                <BANKID>033</BANKID>
                <ACCTID>12345</ACCTID>
                <ACCTTYPE>CHECKING</ACCTTYPE>
              </BANKACCTFROM>
              <BANKTRANLIST>
                <DTSTART>20260101</DTSTART>
                <DTEND>20260510</DTEND>
                <STMTTRN>
                  <TRNTYPE>DEBIT</TRNTYPE>
                  <DTPOSTED>20260505</DTPOSTED>
                  <TRNAMT>-150.50</TRNAMT>
                  <MEMO>OFX Test Purchase</MEMO>
                </STMTTRN>
              </BANKTRANLIST>
              <LEDGERBAL>
                <BALAMT>500000.00</BALAMT>
                <DTASOF>20260510</DTASOF>
              </LEDGERBAL>
            </STMTRS>
          </STMTTRNRS>
        </BANKMSGSRSV1>
      </OFX>
    OFX

    file = Tempfile.new(["test", ".ofx"])
    file.write(ofx_content)
    file.close

    assert_difference("Transaction.count", 1) do
      ImporterService.import(File.open(file.path), @user, @account, format: :ofx)
    end

    tx = @user.transactions.find_by!(description: "OFX Test Purchase")
    assert_equal Date.new(2026, 5, 5), tx.date
    assert_equal 15050, tx.amount
    assert_equal "expense", tx.transaction_type
    assert_equal @account, tx.account
  ensure
    file&.close
    file&.unlink
  end

  test "import_csv skips rows that fail validation" do
    csv = "date,description,amount,type\n2026-05-10,ValidRow,100.00,expense\ninvalid-date,BadRow,50.00,expense\n"
    file = Tempfile.new(["test", ".csv"])
    file.write(csv)
    file.close

    assert_difference("Transaction.count", 1) do
      ImporterService.import(File.open(file.path), @user, @account, format: :csv)
    end
  ensure
    file&.close
    file&.unlink
  end
end

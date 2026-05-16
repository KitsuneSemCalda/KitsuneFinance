require "test_helper"

class BrasilApiServiceTest < ActiveSupport::TestCase
  test "fetch_company_data returns parsed JSON on success" do
    response = OpenStruct.new(success?: true, body: '{"cnpj": "12345678000195", "razao_social": "EMPRESA TESTE"}')
    stub_method(Faraday, :get, ->(*) { response }) do
      data = BrasilApiService.fetch_company_data("12345678000195")
      assert_equal "EMPRESA TESTE", data["razao_social"]
      assert_equal "12345678000195", data["cnpj"]
    end
  end

  test "fetch_company_data returns nil on API failure" do
    response = OpenStruct.new(success?: false, body: "{}")
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_nil BrasilApiService.fetch_company_data("12345678000195")
    end
  end

  test "fetch_company_data returns nil for invalid CNPJ" do
    assert_nil BrasilApiService.fetch_company_data("123")
  end

  test "fetch_company_data sanitizes non-digit characters" do
    response = OpenStruct.new(success?: true, body: '{"cnpj": "12345678000195"}')
    stub_method(Faraday, :get, ->(*) { response }) do
      data = BrasilApiService.fetch_company_data("12.345.678/0001-95")
      assert_equal "12345678000195", data["cnpj"]
    end
  end

  test "fetch_company_data returns nil on network error" do
    stub_method(Faraday, :get, ->(*) { raise Faraday::Error }) do
      assert_nil BrasilApiService.fetch_company_data("12345678000195")
    end
  end

  test "map_cnae_to_category maps alimentacao" do
    assert_equal "Alimentação", BrasilApiService.map_cnae_to_category("Restaurantes e similares")
    assert_equal "Alimentação", BrasilApiService.map_cnae_to_category("Lanchonetes e casas de chá")
    assert_equal "Alimentação", BrasilApiService.map_cnae_to_category("Supermercados")
    assert_equal "Alimentação", BrasilApiService.map_cnae_to_category("Minimercados, mercearias e armazéns")
  end

  test "map_cnae_to_category maps saude" do
    assert_equal "Saúde", BrasilApiService.map_cnae_to_category("Farmácias")
    assert_equal "Saúde", BrasilApiService.map_cnae_to_category("Medicamentos")
  end

  test "map_cnae_to_category transporte" do
    assert_equal "Transporte", BrasilApiService.map_cnae_to_category("Transporte rodoviário")
    assert_equal "Transporte", BrasilApiService.map_cnae_to_category("Táxi")
    assert_equal "Transporte", BrasilApiService.map_cnae_to_category("Locação de veículos")
  end

  test "map_cnae_to_category maps educacao" do
    assert_equal "Educação", BrasilApiService.map_cnae_to_category("Educação infantil")
    assert_equal "Educação", BrasilApiService.map_cnae_to_category("Ensino fundamental")
    assert_equal "Educação", BrasilApiService.map_cnae_to_category("Escolas")
  end

  test "map_cnae_to_category maps vestuario" do
    assert_equal "Compras", BrasilApiService.map_cnae_to_category("Confecção de vestuário")
    assert_equal "Compras", BrasilApiService.map_cnae_to_category("Calçados")
    assert_equal "Compras", BrasilApiService.map_cnae_to_category("Artigos do vestuário")
  end

  test "map_cnae_to_category maps eletronicos" do
    assert_equal "Compras", BrasilApiService.map_cnae_to_category("Eletrônicos")
    assert_equal "Compras", BrasilApiService.map_cnae_to_category("Informática")
    assert_equal "Compras", BrasilApiService.map_cnae_to_category("Eletrodomésticos")
  end

  test "map_cnae_to_category maps lazer" do
    assert_equal "Lazer", BrasilApiService.map_cnae_to_category("Lazer")
    assert_equal "Lazer", BrasilApiService.map_cnae_to_category("Cultura")
    assert_equal "Lazer", BrasilApiService.map_cnae_to_category("Cinemas")
    assert_equal "Lazer", BrasilApiService.map_cnae_to_category("Parques")
  end

  test "map_cnae_to_category maps contas fixas" do
    assert_equal "Contas Fixas", BrasilApiService.map_cnae_to_category("Energia elétrica")
    assert_equal "Contas Fixas", BrasilApiService.map_cnae_to_category("Água")
    assert_equal "Contas Fixas", BrasilApiService.map_cnae_to_category("Telefonia")
  end

  test "map_cnae_to_category returns nil for unknown" do
    assert_nil BrasilApiService.map_cnae_to_category("Atividades não especificadas")
  end

  test "map_cnae_to_category returns nil for blank" do
    assert_nil BrasilApiService.map_cnae_to_category("")
    assert_nil BrasilApiService.map_cnae_to_category(nil)
  end

  test "fetch_banks returns parsed array on success" do
    response = OpenStruct.new(success?: true, body: '[{"code": 341, "name": "Itaú"}]')
    stub_method(Faraday, :get, ->(*) { response }) do
      banks = BrasilApiService.fetch_banks
      assert_equal 1, banks.length
      assert_equal "Itaú", banks[0]["name"]
    end
  end

  test "fetch_banks returns empty array on failure" do
    response = OpenStruct.new(success?: false)
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_equal [], BrasilApiService.fetch_banks
    end
  end

  test "fetch_holidays returns parsed array on success" do
    response = OpenStruct.new(success?: true, body: '[{"date": "2026-01-01", "name": "Confraternização Universal"}]')
    stub_method(Faraday, :get, ->(*) { response }) do
      holidays = BrasilApiService.fetch_holidays(2026)
      assert_equal 1, holidays.length
      assert_equal "Confraternização Universal", holidays[0]["name"]
    end
  end

  test "fetch_holidays returns empty array on failure" do
    response = OpenStruct.new(success?: false)
    stub_method(Faraday, :get, ->(*) { response }) do
      assert_equal [], BrasilApiService.fetch_holidays(2026)
    end
  end
end

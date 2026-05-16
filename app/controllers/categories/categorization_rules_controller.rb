module Categories
  class CategorizationRulesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_category, except: :index

    def index
      @page_title = "Regras de Categorização"
      @rules = current_user.categorization_rules.includes(:category).order(:keyword)
      render "index", layout: "dashboard"
    end

    def create
      @rule = @category.categorization_rules.new(rule_params)
      @rule.user = current_user

      if @rule.save
        redirect_to edit_dashboard_category_path(@category), notice: "Regra adicionada com sucesso."
      else
        redirect_to edit_dashboard_category_path(@category), alert: "Erro ao adicionar regra: #{@rule.errors.full_messages.join(', ')}"
      end
    end

    def destroy
      @rule = current_user.categorization_rules.find(params[:id])
      @rule.destroy
      redirect_to edit_dashboard_category_path(@category), notice: "Regra removida."
    end

    private

    def set_category
      @category = current_user.categories.find(params[:category_id])
    end

    def rule_params
      params.require(:categorization_rule).permit(:keyword)
    end
  end
end

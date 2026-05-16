class CategorizationSuggestionsController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard"

  def index
    @page_title = "Regras de Categorização"
    @suggestions = current_user.categorization_suggestions.includes(:category)
  end

  def new
    @page_title = "Nova Regra"
    @suggestion = current_user.categorization_suggestions.new
  end

  def create
    @suggestion = current_user.categorization_suggestions.new(suggestion_params)
    if @suggestion.save
      redirect_to dashboard_categorization_suggestions_path, notice: "Regra criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @suggestion = current_user.categorization_suggestions.find(params[:id])
    @suggestion.destroy
    redirect_to dashboard_categorization_suggestions_path, notice: "Regra removida."
  end

  private

  def suggestion_params
    params.require(:categorization_suggestion).permit(:keyword, :category_id)
  end
end

class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: %i[edit update destroy]
  layout "dashboard"

  def index
    @page_title = "Categorias"
    @categories = current_user.categories.order(:transaction_type, :name)
  end

  def new
    @page_title = "Nova Categoria"
    @category = current_user.categories.new(transaction_type: params[:transaction_type] || "expense")
  end

  def create
    @category = current_user.categories.new(category_params)
    if @category.save
      redirect_to dashboard_categories_path, notice: "Categoria criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @page_title = "Editar Categoria"
  end

  def update
    if @category.update(category_params)
      redirect_to dashboard_categories_path, notice: "Categoria atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to dashboard_categories_path, notice: "Categoria excluída."
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :transaction_type, :color, :icon)
  end
end

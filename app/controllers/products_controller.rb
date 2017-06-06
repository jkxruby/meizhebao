class ProductsController < ApplicationController

	def index

		if params[:type]
			@category = Category.find(params[:type])

			if @category.leaf?
				@products = Product.where(category: @category)
				@current_gender_category = @products.first.current_gender_category
			else
				@products = []
				@category.leaves.each do |category|
					@products += category.products
				end
				@products
				@current_gender_category = @products.first.current_gender_category
			end

		else 
			@products = Product.all
			@current_gender_category = Category.find_by(name: "女")
		end
	end

	def show
		@product = Product.find_by_friendly_id!(params[:id])
		@photos = @product.photos.all
		@current_gender_category = @product.current_gender_category
		# @product.variants.build
		@variants = @product.variants
		@colors = @variants.map { |v| v.color}.uniq
		@sizes = @variants.map { |v| v.size}.uniq
	end

	def select_color
		# binding.pry
		@product = Product.find_by_friendly_id!(params[:id])
		@variants = @product.variants
		@color = params[:color]
		@size = params[:size]
		unless @color.blank?
			unless @size.blank?
				@variant = @variants.where(color: @color, size: @size).first
				@current_quantity = @variant.quantity unless @variant.blank?
			else
				current_variants = @variants.where(color: @color)
				@current_quantity = 0
				current_variants.each do |v|
					@current_quantity += v.quantity
				end
			end
			@colors = @variants.map { |v| v.color}.uniq
			@sizes = @variants.where(color: @color).map { |v| v.size }.uniq
		else
			unless @size.blank?
				current_variants = @variants.where(size: @size)
				@current_quantity = 0
				current_variants.each do |v|
					@current_quantity += v.quantity
				end
			else
				@current_quantity = 0
				@variants.each do |v|
					@current_quantity += v.quantity
				end
			end
			@sizes = @variants.map{ |v| v.size }.uniq
			@colors = @variants.where(size: @size).map{ |v| v.color }.uniq
		end

		# binding.pry
		render :json => { :message => "ok", :current_quantity => @current_quantity, current_color: @color, current_size: @size, colors: @colors, sizes: @sizes }

	    # respond_to do |format|
	    #   format.html  # 如果客户端要求 HTML，则回传 index.html.erb
	    #   format.js    # 如果客户端要求 JavaScript，回传 index.js.erb
	    # end
	end

	def quantity_plus_one
		
	end

	def quantity_minus_one
		
	end

	def add_to_cart
		@product = Product.find_by_friendly_id!(params[:id])
		@quantity = params[:quantity].to_i
		@variant = Variant.find_by(product: @product, color: params[:color], size: params[:size])


		if !current_cart.variants.include?(@variant)
			current_cart.add_variant_to_cart(@variant, @quantity)
			flash[:notice] = "你已成功将 #{@variant.product.title} 加入购物车"
		else
			flash[:warning] = "你的购物车内已有此物品"
		end
		redirect_to :back
	end

	def update
		@product = Product.find_by_friendly_id!(params[:id])
		@current_variant = Variant.find_by(product: @product, color: product_params[:color], size: product_params[:size])

		if @product.update(product_params)
			redirect_to :back
		else
			render :show
		end
	end

	def product_params
		params.require(:product).permit(:variants_attributes => [:id, :color, :size])
	end

	helper_method :current_variant
	def current_variant
		@current_variant ||= find_variant
	end

	def find_variant
		@product.variants.first
	end

end

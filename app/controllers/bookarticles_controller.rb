# encoding: utf-8

class BookarticlesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @menu = "myarticles"
    @book_id = params[:book_id]
    
    if !@book_id.nil?
      @book_basic = Book_basic.get(@book_id.to_i)
    else
      
    end
    render 'bookarticle'  
  end
  


  # PUT /articles/1
  # PUT /articles/1.xml
  def update
    @article = Book_article.get(params[:id].to_i)
    
    @article.title = params[:title]
    @article.content = params[:content]
    
    puts_message @article.title 
    puts_message @article.content 
    
    if @article.save
      render :partial => "result"    
    end
  end

  def left_list_delete
    
    book_id = params[:book_id].to_i

    @book_basic = Book_basic.first(:id => book_id, :user_id => current_user.id)
    @book_articles = Book_article.all(:book_basic_id => book_id, :user_id => current_user.id)
    
    if params[:need_reload] == "true"
      @need_reload = true
    else
      @need_reload = false
    end
    

    tmp_msg = "on deleting "+@book_basic.title+"'s articles: total "+@book_articles.count.to_s+" articles ..."    
    puts_message tmp_msg

    if @book_basic.destroy 
      if @book_articles.destroy
        @book_list = Book_basic.all(:user_id => current_user.id)
      else
        puts_message "error occured on progress of deleting Book_articles table..."        
      end

      render :partial => "new_book_list", :object => @book_list, :object => @need_reload
      # render 'bookarticle'
    else
      puts_message "error occured on progress of deleting Book_basic table..."
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.xml
  def destroy
    @article = Article.get(params[:id])
    
    # 업로드된 이미지 파일 삭제 =========================================================================
    file_name = @article.image_filename
    if  File.exist?(IMAGE_PATH + file_name)
      	File.delete(IMAGE_PATH + file_name)         #original image file
      	File.delete(IMAGE_PATH + "t_" + file_name)  #thumbnail file
    end
    # 업로드된 이미지 파일 삭제 =========================================================================
    @article.destroy

    respond_to do |format|
      format.html { redirect_to(articles_url) }
      format.xml  { head :ok }
    end
  end
  
end

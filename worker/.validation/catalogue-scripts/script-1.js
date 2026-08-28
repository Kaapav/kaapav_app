
(function(){
  console.log('ðŸš€ Loading Intelligence Layer...');
  
  // Verify fbq exists
  if(typeof fbq === 'undefined'){
    console.error('âŒ Meta Pixel (fbq) not found! Base pixel failed to load.');
    return;
  }
  
  const WORKER_URL='https://kaapav-ad-engine-api.kaapavin.workers.dev';
  const CAPI_EVENTS = ['AddToCart','InitiateCheckout','Purchase','ViewContent','AddToWishlist'];
  const PIXEL_ID='1788777195431410';
  const DOMAIN=window.location.hostname;
  const SOURCE_SITE='catalogue';
  
  const params=new URLSearchParams(window.location.search);
  const utm={
    source:params.get('utm_source')||'',
    medium:params.get('utm_medium')||'',
    campaign:params.get('utm_campaign')||'',
    creative:params.get('creative')||'',
    adset:params.get('adset')||'',
    ad:params.get('ad')||'',
    content:params.get('utm_content')||'',
    fbclid:params.get('fbclid')||''
  };
  
  const device=/Mobi|Android/i.test(navigator.userAgent)?'mobile':'desktop';
function getCookie(n){const v=`; ${document.cookie}`;const p=v.split(`; ${n}=`);return p.length===2?p.pop().split(';').shift():'';}
const fbclid=params.get('fbclid')||'';
const _fbp=getCookie('_fbp');
const _fbc=getCookie('_fbc')||(fbclid?`fb.1.${Date.now()}.${fbclid}`:'');
  
  let sessionId=sessionStorage.getItem('kpv_cat_sid');
  if(!sessionId){
    sessionId='kpv_cat_'+Date.now()+'_'+Math.random().toString(36).substr(2,9);
    sessionStorage.setItem('kpv_cat_sid',sessionId);
  }
  
function logIntelligence(event,extra){
  try{
    const payload={
      event,url:window.location.href,utm,device,source_site:SOURCE_SITE,
      session_id:sessionId,referrer:document.referrer,timestamp:new Date().toISOString(),
      pixel_id:PIXEL_ID,domain:DOMAIN,_fbp,_fbc,fbclid,...extra
    };
    console.log(`ðŸ“¤ SENDING: ${event}`,{event_id:payload.event_id||'',_fbp,_fbc});
    fetch(WORKER_URL+'/api/pixel-events',{
      method:'POST',headers:{'Content-Type':'application/json'},
      body:JSON.stringify(payload),keepalive:true
    })
    .then(res=>{console.log(`âœ… Worker response: ${res.status} ${event}`);return res.json();})
    .then(d=>{console.log('âœ… Worker data:',d);})
    .catch(()=>{});
  }catch(e){}
}
  
function genId(e){return `${sessionId}_${e}_${Date.now()}_${Math.random().toString(36).substr(2,9)}`;}
function metaTrack(event,data,eid){
  if(typeof fbq!=='undefined'){
    const _eid=eid||genId(event);
    fbq('track',event,data||{},{eventID:_eid});
    console.log('ðŸ“Š Meta Event:',event,{eid:_eid,source:'catalogue_app',...(data||{})});
  }
}
  
  function metaTrackCustom(event,data){
    if(typeof fbq!=='undefined'){
      fbq('trackCustom',event,data||{});
      console.log('ðŸ“Š Custom Event:',event,data);
    }
  }
  
  window.kpvTrack={
    
    pageView:function(screenName){
      fbq('track','PageView');
      metaTrackCustom('ScreenView',{
        screen_name:screenName||'unknown',
        source:'catalogue_app'
      });
      logIntelligence('PageView',{screen:screenName||'unknown'});
    },
    
    catalogueView:function(){
      metaTrackCustom('CatalogueView',{
        page_type:'home',
        source:'catalogue_app'
      });
      logIntelligence('CatalogueView',{});
    },
    
    categoryView:function(categoryName){
      metaTrackCustom('CatalogueCategoryView',{
        category:categoryName,
        page_type:'category',
        source:'catalogue_app'
      });
      logIntelligence('CatalogueCategoryView',{category:categoryName});
    },
    
    viewContent:function(product){
      const eid=genId('ViewContent');
      metaTrack('ViewContent',{
        content_name:product.name,
        content_type:'product',
        content_category:product.category||'',
        content_ids:[product.id||''],
        value:product.price,
        currency:'INR',
        product_id:product.id,
        product_name:product.name,
        product_category:product.category||'',
        product_price:product.price,
        page_type:'product_detail',
        source:'catalogue_app',
        eid
      });
      logIntelligence('ViewContent',{
        event_id:eid,
	product:product.name,
        product_id:product.id,
        price:product.price,
        category:product.category,
        image:product.image,
        eid
      });
    },
    
    productClick:function(product){
      metaTrackCustom('CatalogueProductClick',{
        product_id:product.id,
        product_name:product.name,
        product_category:product.category||'',
        product_price:product.price,
        page_type:'product_listing',
        source:'catalogue_app'
      });
      logIntelligence('CatalogueProductClick',{
        product:product.name,
        product_id:product.id,
        price:product.price,
        category:product.category
      });
    },
    
    addToWishlist:function(product){
      const eid=genId('AddToWishlist');
      metaTrack('AddToWishlist',{
        content_name:product.name,
        content_ids:[product.id||''],
        value:product.price,
        currency:'INR',
        product_id:product.id,
        product_name:product.name,
        product_category:product.category||'',
        product_price:product.price,
        source:'catalogue_app',
        eid
      });
      logIntelligence('AddToWishlist',{
        event_id:eid,
        product:product.name,
        product_id:product.id,
        price:product.price,
        category:product.category,
        eid
      });
    },
    
    addToCart:function(product,quantity){
      const totalValue=product.price*(quantity||1);
      const eid=genId('AddToCart');
      metaTrack('AddToCart',{
        content_name:product.name,
        content_ids:[product.id||''],
        value:totalValue,
        currency:'INR',
        num_items:quantity||1,
        product_id:product.id,
        product_name:product.name,
        product_category:product.category||'',
        product_price:product.price,
        quantity:quantity||1,
        source:'catalogue_app',
        eid
      });
      logIntelligence('AddToCart',{
        product:product.name,
        product_id:product.id,
        price:product.price,
        quantity:quantity||1,
        category:product.category,
        event_id:eid
      });
    },
    
    viewCart:function(cartValue,numItems){
      metaTrackCustom('ViewCart',{
        value:cartValue,
        currency:'INR',
        num_items:numItems,
        page_type:'cart',
        cart_value:cartValue,
        cart_items:numItems,
        source:'catalogue_app'
      });
      logIntelligence('ViewCart',{
        value:cartValue,
        num_items:numItems
      });
    },
    
    initiateCheckout:function(data){
      const eid=genId('InitiateCheckout');
      metaTrack('InitiateCheckout',{
        value:data.value,
        currency:'INR',
        num_items:data.numItems||1,
        content_ids:data.productIds||[],
        checkout_value:data.value,
        checkout_items:data.numItems||1,
        page_type:'checkout',
        source:'catalogue_app',
        eid
      });
      logIntelligence('InitiateCheckout',{
        value:data.value,
        num_items:data.numItems,
        products:data.products||[],
        event_id:eid
      });
    },
    
    addPaymentInfo:function(value){
      metaTrack('AddPaymentInfo',{
        value:value,
        currency:'INR',
        payment_method:'razorpay',
        payment_value:value,
        source:'catalogue_app'
      });
      logIntelligence('AddPaymentInfo',{
        value:value,
        payment_method:'razorpay'
      });
    },
    
purchase:function(data){
  const eid=genId('Purchase');
  metaTrack('Purchase',{
    value:data.value,
    currency:'INR',
    transaction_id:data.orderId,
    num_items:data.numItems||1,
    content_ids:data.productIds||[],
    content_type:'product',
    contents:data.contents||[],
    order_id:data.orderId,
    order_value:data.value,
    order_items:data.numItems||1,
    payment_method:'razorpay',
    shipping_method:'shiprocket',
    source:'catalogue_app',
    eid
  });
logIntelligence('Purchase',{
  value:data.value,
  order_id:data.orderId,
  num_items:data.numItems,
  product_ids:data.productIds||[],
  contents:data.contents||[],
  phone:data.phone||'',
  name:data.name||'',
  payment_method:'razorpay',
  shipping_method:'shiprocket',
  utm:utm,
  event_id:eid
});
    },
    
    whatsappIntent:function(product){
      metaTrack('Contact');
      metaTrackCustom('WhatsAppIntent',{
        product_id:product?(product.id||''):'',
        product_name:product?(product.name||''):'',
        product_category:product?(product.category||''):'',
        product_price:product?(product.price||0):0,
        contact_type:'whatsapp',
        source:'catalogue_app'
      });
      logIntelligence('WhatsAppIntent',{
        product:product?product.name:'',
        product_id:product?product.id:'',
        price:product?product.price:0
      });
    },
    
    search:function(query,resultsCount){
      metaTrack('Search',{
        search_string:query,
        search_query:query,
        search_results:resultsCount||0,
        source:'catalogue_app'
      });
      logIntelligence('Search',{
        query:query,
        results_count:resultsCount||0
      });
    }
    
  };
  
  // Initial load
  logIntelligence('AppLoad',{});
  metaTrackCustom('CatalogueView',{page_type:'home',source:'catalogue_app'});
  logIntelligence('CatalogueView',{});
  
  // Scroll tracking
  const scrollMilestones={25:false,50:false,75:false,90:false};
  window.addEventListener('scroll',function(){
    const pct=Math.round((window.scrollY/Math.max(document.body.scrollHeight-window.innerHeight,1))*100);
    Object.keys(scrollMilestones).forEach((m)=>{
      const milestone=parseInt(m);
      if(pct>=milestone&&!scrollMilestones[m]){
        scrollMilestones[m]=true;
        logIntelligence('ScrollDepth'+milestone,{pct});
      }
    });
  },{passive:true});
  
  // Time tracking
  [15,30,60,120,300].forEach((s)=>{
    setTimeout(()=>{logIntelligence('TimeOnSite'+s+'s',{seconds:s})},s*1000);
  });
  
  // Exit intent
  let exitLogged=false;
  document.addEventListener('mouseleave',function(e){
    if(e.clientY<=0&&!exitLogged){
      exitLogged=true;
      logIntelligence('ExitIntent',{});
    }
  });
  
  console.log('âœ… KAAPAV Catalogue Pixel v2.1 ðŸ“Š Event Parameters Active');
  console.log('ðŸ”¥ window.kpvTrack ready');
  
})();

import Stripe from 'https://esm.sh/stripe@15.4.0?target=deno'; 

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2024-04-10', 
  httpClient: Stripe.createFetchHttpClient(),
});

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*', 
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: corsHeaders,
    });
  }

  try {
    const { bookingId, amount, currency, metadata } = await req.json();

    if (!bookingId || !amount || !currency) {
      return new Response(JSON.stringify({ error: 'Missing required parameters' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

     const paymentIntent = await stripe.paymentIntents.create({
       amount: amount, 
       currency: currency, 
       automatic_payment_methods: {
         enabled: true, 
       },
       metadata: { 
         booking_id: bookingId,
          user_id: metadata?.user_id 
       },
     });

    const customer = await stripe.customers.create({
        metadata: {
             user_id: metadata?.user_id
        }
    });

    const ephemeralKey = await stripe.ephemeralKeys.create(
       { customer: customer.id },
       { apiVersion: '2024-04-10' } 
    );


    return new Response(JSON.stringify({
      paymentIntent: paymentIntent.client_secret,
      ephemeralKey: ephemeralKey.secret,
      customer: customer.id,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Stripe API error:', error); 

    let errorMessage = 'An unexpected error ocurred';
    if (error instanceof Error) {
      errorMessage = error.message;
    }

    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

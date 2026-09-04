export default async function handler(req, res) {
  // CORS Headers for Vercel
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization'
  );

  // Handle OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  const targetUrl = req.query.url;
  
  if (!targetUrl) {
    return res.status(400).json({ error: 'Missing url parameter' });
  }
  
  try {
    const parsedUrl = new URL(targetUrl);
    if (!parsedUrl.hostname.endsWith('logiciely.com')) {
      return res.status(403).json({ error: 'Only logiciely.com URLs are allowed' });
    }

    // Forward the request to the target URL
    const fetchOptions = {
      method: req.method,
      headers: {
        'Accept': req.headers['accept'] || 'application/json',
        'User-Agent': req.headers['user-agent'] || 'Vercel-Proxy'
      }
    };

    // Forward body if present
    if (['POST', 'PUT', 'PATCH'].includes(req.method) && req.body) {
      fetchOptions.body = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
      fetchOptions.headers['Content-Type'] = req.headers['content-type'] || 'application/json';
    }

    const response = await fetch(targetUrl, fetchOptions);
    
    // Pass back the response headers (especially Content-Type)
    const contentType = response.headers.get('content-type');
    if (contentType) {
      res.setHeader('Content-Type', contentType);
    }
    
    // Handle binary or text data
    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    
    res.status(response.status).send(buffer);
  } catch (error) {
    console.error('[VERCEL PROXY] Error:', error);
    res.status(500).json({ error: 'Proxy failed to fetch target: ' + error.message });
  }
}

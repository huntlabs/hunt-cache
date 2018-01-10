
module zhang2018.radix;

import std.stdio;
import core.memory;
import core.stdc.string;

import zhang2018.common.Log;








// vitrual struct.

struct raxNode
{
	uint args;
			  //	1 	iskey	
			  //	1	isnull	don't store it 
			  //	1	iscompr 
			  //	29	size

	//void *data;

	//	node is not compr
	//  [abc][a-ptr][b-ptr][c-ptr](value-ptr?)
	//	
	//  node is compr
	//	[xyz][z-ptr](value-ptr?)
pragma(inline, true):

	@property char *str()
	{
		return cast(char*)(&this + 1);
	}

	@property  bool iskey()
	{
		return cast(bool)(args & 0x80000000);
	}
	
	 @property bool iskey(bool value)
	{
		if(value)
			args = args | 0x80000000;
		else
			args = args & (~0x80000000);

		return value;
	}

	@property bool isnull()
	{
		return cast(bool)(args & 0x40000000);
	}
	
	@property bool isnull( bool value)
	{
		if(value)
			args = args| 0x40000000;
		else
			args = args & (~0x40000000);

		return value;
	}

	@property bool iscompr()
	{
		return cast(bool)(args & 0x20000000);
	}
	
	@property bool iscompr( bool value)
	{
		if(value)
			args = args | 0x20000000;
		else
			args = args & (~0x20000000);
		
		return value;
	}



	
	 @property uint size()
	{
		return args & 0x1FFFFFFF;
	}

	 @property uint size(uint value)
	{
		uint v = args & (~0x1FFFFFFF);
		v += value;
		args = v;
		return value;
	}

	@property raxNode** orgin()
	{
		return cast(raxNode**)(str+size);
	}

	@property raxNode * next()
	{
		return *orgin;
	}

	@property raxNode *next(raxNode *n)
	{
		*orgin = n;
		return n;
	}




	@property raxNode * nextChild(uint index)
	{
		if(index >= size)
			log_error( index , " " , size);
		return orgin[index];
	}

	@property raxNode *nextChild(uint index , raxNode *n)
	{
		orgin[index] = n;
		return n;
	}



	@property void *value()
	{
		if(iscompr)
			return orgin[1];
		else
			return orgin[size];
	}


	@property void * value(void *v)
	{
		if(iscompr)
			orgin[1] = cast(raxNode *)v;
		else
			orgin[size] = cast(raxNode *)v;
		return v;
	}




	//alloc non-compr node
	static raxNode* New(uint children , bool hasdata)
	{
		long nodesize = raxNode.sizeof + children + (raxNode*).sizeof * children;
		if(hasdata)
			nodesize += (void*).sizeof;

		raxNode *n = cast(raxNode*)GC.malloc(nodesize);
		if( n == null) return null;

		n.iskey = false;
		n.isnull = false;
		n.iscompr = false;
		n.size = children;

		return n;
	}

	static raxNode *NewComp(uint length , bool hasdata)
	{
		long nodesize = raxNode.sizeof + length + (raxNode *).sizeof;
		if(hasdata)
			nodesize += (void *).sizeof;

		raxNode *n = cast(raxNode*)GC.malloc(nodesize);
		if( n == null) return null;

		n.iskey = false;
		n.isnull = false;
		n.iscompr = true;
		n.size = length;


		return n;

	}


	static raxNode *Renew(raxNode *n , uint children , bool hasdata)
	{
		long nodesize = raxNode.sizeof + children + (raxNode*).sizeof * children;
		if(hasdata)
			nodesize += (void *).sizeof;

		auto node = cast(raxNode*)GC.realloc(n , nodesize);
		if(node == null) return null;
		node.iscompr = false;
		return node;
	}


	static raxNode *RenewComp(raxNode *n , uint length , bool hasdata)
	{
		long nodesize= raxNode.sizeof + length + (raxNode*).sizeof * length;
		if(hasdata)
			nodesize += (void *).sizeof;

		auto node = cast(raxNode*) GC.realloc(n , nodesize);
		if( node == null) return null;
		node.iscompr = true;
		return node;
	}

	static void Free(raxNode *n)
	{
		GC.free(n);
	}




};

struct raxItem
{
	raxNode *n;
	int		index;
}







struct rax
{
	raxNode 	*head;
	long	 	numele;
	long		numnodes;

	static rax * New()
	{
		rax *r = cast(rax *)GC.malloc(rax.sizeof);
		if (r == null) return null;
		
		r.numele = 0;
		r.numnodes = 1;
		r.head = raxNode.NewComp(0 , false);

		if (r.head == null)
		{
			Free(r);
			return null;
		}
		else
		{
			return r;
		}
	}

 



	void RecursiveFree(raxNode *n)
	{
		int numchildren = 0;
		if(n.iscompr)
		{
			numchildren = n.size > 0 ? 1: 0;
		}
		else
		{
			numchildren = n.size;
		}
		while(numchildren--){
			RecursiveFree(n.nextChild(numchildren));  
		}
		raxNode.Free(n);
		numnodes--;
	}

	static void Free(rax *r)
	{
		r.RecursiveFree(r.head);
		GC.free(r);
	}


	bool Remove(const ubyte[] s)
	{
		raxNode *h = head;
		raxNode *p = head;
		raxItem[] ts;
		uint index = 0;
		uint splitpos = 0;
		uint last = find(s , h , p , index , splitpos , ts);
		if(last > 0){
			log_error("remove " , cast(string)s , " " ,last);
			return false;
		}
		else{
			if(h.iskey) {
				numele--;
				h.iskey = false;
				if(h.size == 0)
				{

					if( p.iscompr)
					{
						//#1	最后一个节点为空	父节点压缩节点 且是key 则去除父节点			
						//		   (x)
						//			|			- 'test'       (x)
						//		('test')	------------->		|
						//			|							()
						//			()
						//

						if(p.iskey)
						{
							h.iskey = true;
							h.value = p.value;
							if(p == head)
							{
								head = h;
							
							}
							else
							{
								raxItem item = ts[$ - 2];
								item.n.nextChild(item.index , h);
							}
							numnodes -= 1;
							raxNode.Free(p);
							log_info("#####r1");
						}
						//#2	最后一个节点为空	父节点是压缩节点 不是key 父父节点必须是非压缩节点  
						//		   (t)
						//			|
						//		   (A)
						//			|
						//		  ['xyz']
						//		   /  \				- 'test'
						//		 (B)	('test')  ---------------->	
						//    	  |		|			
						//		 (C)   ()
						//
						//
						//		#1  当['xy']	 size == 2
						//				#1 当['xy']不是key，A为压缩节点 && 当B为压缩节点 且不是key,合并三项
						//		   (t)
						//			|
						//		   (A)
						//			|
						//		  ['xy']
						//		   /  \				- 'test'				(t)
						//		 (B)	('test')  ---------------->			|
						//    	  |		|								(A + 'x' + B)
						//		 (C)   ()									|
						//													(C)
						//
						//				#2 当['xy']不是key，A为压缩节点 , 合并两项
						//		   (t)
						//			|
						//		   (A)
						//			|										
						//		  ['xy']									
						//		   /  \				- 'test'				(t)
						//		 (B)	('test')  ---------------->			|
						//    	  |		|								( A  + 'x')
						//		 (C)   ()									|
						//													(B)
						//													|
						//													(C)
						//
						//				#3 当B为压缩节点 且不是key ， 合并两项
						//		   (t)
						//			|
						//		   (A)
						//			|										(t)
						//		  ['xy']									|
						//		   /  \				- 'test'				(A)
						//		 (B)	('test')  ---------------->			|
						//    	  |		|								( 'x' + B)
						//		 (C)   ()									|
						//													(C)
						//
						//				#4 当都不能合并时
						//		   (t)
						//			|
						//		   (A)
						//			|										(t)
						//		  ['xy']									|
						//		   /  \				- 'test'				(A)
						//		 (B)	('test')  ---------------->			|
						//    	  |		|								  ( 'x')
						//		 (C)   ()									|
						//													(B)
						//													|
						//													(C)
						else // pp exist. & pp is non compr
						{
							//pp
							if( p == head)
							{
								head = h;
								numnodes -= 1;
								log_info("#####r2");
							}
							else{
								raxItem t1 = ts[$ - 2];
								raxNode *r1 = ts[$ - 2].n;
								if( r1.size == 2){
								
									raxNode *pp = null;
									if(ts.length >= 3)
										pp = ts[$ - 3].n;
									bool ppCombine =  pp && pp.iscompr && !r1.iskey;
									raxNode *nh = r1.nextChild(r1.size - 1 - t1.index);
									bool nhCombie = nh.iscompr && !nh.iskey;



									if( ppCombine && nhCombie)
									{
										bool hasdata = pp.iskey && !pp.isnull;
										raxNode *u = raxNode.NewComp(pp.size + nh.size + 1 , hasdata);
										memcpy(u.str , pp.str , pp.size);
										memcpy(u.str + pp.size , r1.str + r1.size - 1 - t1.index , 1);
										memcpy(u.str + pp.size + 1 , nh.str ,  nh.size);

										u.iskey = pp.iskey;
										if(hasdata)
										{
											u.value = pp.value;
										}
										u.next( nh.next);
										if( pp == head)
										{
											head = u;
										}
										else{
											raxItem item = ts[$ - 4];
											item.n.nextChild(item.index , u);
										}
										raxNode.Free(nh);
										raxNode.Free(pp);
										raxNode.Free(p);
										raxNode.Free(h);
										raxNode.Free(r1);
										numnodes -= 4;
										log_info("#####r211");

									}
									else if(ppCombine)
									{
										bool hasdata = r1.iskey && !r1.isnull;
										raxNode *u = raxNode.NewComp(pp.size + 1 , hasdata);
										memcpy(u.str , pp.str , pp.size);
										memcpy(u.str + pp.size , r1.str+ r1.size - 1 - t1.index , 1);
										u.next(nh);
										u.iskey = r1.iskey;
										if(hasdata)
										{
											u.value = r1.value;
										}
										
										if( pp == head)
										{
											head = u;
										}
										else{
											raxItem item = ts[$ - 4];
											item.n.nextChild(item.index , u);
										}
										raxNode.Free(pp);
										raxNode.Free(p);
										raxNode.Free(h);
										raxNode.Free(r1);
										numnodes -= 3;
										
										log_info("#####r212");
									}
									else if(nhCombie)
									{
										bool hasdata = r1.iskey && !r1.isnull;
										raxNode* u = raxNode.NewComp(1 + nh.size , hasdata);
										memcpy(u.str  , r1.str + r1.size - 1 - t1.index , 1);
										memcpy(u.str + 1,  nh.str , nh.size);
										u.iskey = r1.iskey;

										if(hasdata)
										{
											u.value = r1.value;
										}

										u.next(nh.next);

										
										if( r1 == head)
										{
											head = u;
										}
										else
										{
											raxItem item = ts[$ - 3];
											log_info(getStr(item.n));
											item.n.nextChild(item.index , u);
										}
										raxNode.Free(nh);
										raxNode.Free(p);
										raxNode.Free(h);
										raxNode.Free(r1);
										numnodes -= 3;
										log_info("#####r213");
									}
									else{
										bool hasdata = r1.iskey && !r1.isnull;
										raxNode *n = raxNode.NewComp(1 , hasdata);
										n.iskey = r1.iskey;
										if(hasdata)
											n.value = r1.value;
										n.str[0] = r1.str[r1.size - 1 - t1.index];
										n.next( r1.nextChild(r1.size - 1 - t1.index));
										
										if(r1 == head)
										{
											head = n;
										}
										else{
											raxItem item = ts[$ - 3];
											item.n.nextChild(item.index , n);
										}
										
										raxNode.Free(h);
										raxNode.Free(p);
										raxNode.Free(r1);
										numnodes -= 2;
										log_info("#####r214");
									}


								}
								//		#1  当['xyz'] 的size > 2
								//				
								//		   (t)										(t)
								//			|										 |
								//		   (A)										(A)
								//			|										 |
								//		  ['xyz']                                   ['xz']
								//		   /  \    \ 				- 'test'	    /   \
								//		 (B)('test') (D)  ---------------->		  ('B')   (D)
								//    	  |		|								
								//		 (C)   ()									
								//													
								else if (r1.size > 2){

									bool hasdata = r1.iskey && !r1.isnull;
									raxNode *u = raxNode.New(r1.size - 1, hasdata);
									u.iskey = r1.iskey;
									if(hasdata)
									{
										u.value = r1.value;
									}
									
									log_info("index " , t1.index , " " , r1.size);
									
									if( t1.index == 0)
									{
										memcpy(u.str , r1.str + 1 , r1.size - 1 );
									}
									else if(t1.index == r1.size - 1)
									{	
										memcpy(u.str , r1.str , r1.size - 1);
									}
									else
									{
										memcpy(u.str , r1.str  , t1.index);
										memcpy(u.str + t1.index  , r1.str + t1.index + 1, r1.size - t1.index -1);
									}

									log_info(getStr(u));

									for( uint i , j  = 0 ; i < r1.size ; )
									{
										if( i != t1.index)
											u.orgin[j++] = r1.orgin[i++];
										else
											i++;
									}

									//raxNode *test = null;

									if(r1 == head)
									{
										head = u;
									}
									else{
										raxItem i = ts[$ - 3];
										log_info(i.index , " ",  getStr(i.n));
										i.n.nextChild(i.index , u);
										Recursiveshow(u ,0);
										Recursiveshow(i.n ,0);
									
									}
									
									raxNode.Free(r1);
									raxNode.Free(h);
									raxNode.Free(p);
									numnodes -= 2;
									log_info("####r22");

								}
								else{
									log_error("####r23 none exist");
								}


							}



						}
					}
					//	#3  当父节点为非压缩节点
					//
					//
					//			 (A)
					//			  |					A+'y'
					//			['xyz']			----------->
					//			 / |  \
					//			(C) () (D)
					//
					//
					//
					//		#1 当['xy'] 的size == 2时
					//				
					//				当#1 ['xy']非key，且(C)非key , 合并三项
					//			 (t)
					//			  |
					//			 (A)
					//			  |					A+'y'			   (t)
					//			['xy']			----------->      	 	|
					//			 / |								(A + 'x' + C)
					//			(C) () 									|
					//			 |										(D)
					//			(D)		
					//
					//		
					//				
					//				当#2 ['xy']非key , 合并两项
					//			 (t)
					//			  |
					//			 (A)
					//			  |					A+'y'			   (t)
					//			['xy']			----------->      	 	|
					//			 / |								(A + 'x' )
					//			(C) () 									|
					//			 |										(C)
					//			(D)										|
					//													(D)
					//				当#3 (C)非key , 合并两项
					//			 (t)
					//			  |									   (t)
					//			 (A)								    |
					//			  |					A+'y'			   (A)
					//			['xy']			----------->      	 	|
					//			 / |								('x' + C)
					//			(C) () 									|
					//			 |										(D)
					//			(D)	
					//
					//			   当#4 无合并
					//											
					//			 (t)
					//			  |									   (t)
					//			 (A)								    |
					//			  |					A+'y'			   (A)
					//			['xy']			----------->      	 	|
					//			 / |								  ('x')
					//			(C) () 									|
					//			 |										(C)
					//			(D)										|	
					//													(D)
					else if(!p.iscompr)
					{
						// noncompr to compr
						log_info("p " , getStr(p));
						if(p.size == 2){
						
								raxNode *pp = null ;
								if(ts.length >= 2)
									pp = ts[$ - 2].n;
								bool ppCombine = pp && pp.iscompr && !p.iskey;
								raxNode *nh = p.nextChild(p.size - 1 - index);

								log_info("nh " , getStr(nh));
								bool nhCombie = nh.iscompr && !nh.iskey;
								
								log_info(ppCombine , " " , nhCombie);
								
								// #1 合并3个
								if( ppCombine && nhCombie)
								{
									bool hasdata = pp.iskey && !pp.isnull;
									raxNode *u = raxNode.NewComp(pp.size + nh.size + 1 , hasdata);
									memcpy(u.str , pp.str , pp.size);
									memcpy(u.str + pp.size , p.str + p.size - 1 - index , 1);
									memcpy(u.str + pp.size + 1 , nh.str ,  nh.size);

									u.iskey = pp.iskey;	
									if(hasdata)
										u.value = pp.value;

									u.next( nh.next);
									if( pp == head)
									{
										head = u;
									}
									else{
										raxItem item = ts[$ - 3];
										item.n.nextChild(item.index , u);
									}
									raxNode.Free(nh);
									raxNode.Free(pp);
									raxNode.Free(p);
									raxNode.Free(h);

									numnodes -= 3;

									log_info("#####r311");
								}
								// #2 
								else if(ppCombine)
								{
									
									bool hasdata = pp.iskey && !pp.isnull;
									raxNode *u = raxNode.NewComp(pp.size + 1 , hasdata);
									memcpy(u.str , pp.str , pp.size);
									memcpy(u.str + pp.size , p.str+ p.size - 1 - index , 1);
									u.next(nh);
									u.iskey = pp.iskey;
									if(hasdata)
										u.value = pp.value; 
									
									if( pp == head)
									{
										head = u;
									}
									else{
										raxItem item = ts[$ - 3];
										item.n.nextChild(item.index , u);
									}
									raxNode.Free(pp);
									raxNode.Free(p);
									raxNode.Free(h);
									numnodes -= 2;

									log_info("#####r312");
								}
								else if(nhCombie)
								{
									bool hasdata = p.iskey && !p.isnull;
									raxNode* u = raxNode.NewComp(1 + nh.size , hasdata);
									memcpy(u.str  , p.str + p.size - 1 - index , 1);
									memcpy(u.str + 1,  nh.str , nh.size);
									u.iskey = p.iskey;
									u.next(nh.next);
									if(hasdata)
										u.value = p.value;
									if( p == head)
									{
										head = u;
									}
									else
									{
										raxItem item = ts[$ - 2];
										item.n.nextChild(item.index , u);
									}
									raxNode.Free(nh);
									raxNode.Free(p);
									raxNode.Free(h);
									numnodes -= 2;
									log_info("#####r313");
								}
								// p.iskey or no combine.
								else{
									bool hasdata = p.iskey && !p.isnull;
									raxNode *n = raxNode.NewComp(1 , hasdata);
									n.iskey = p.iskey;
									if(hasdata)
										n.value = p.value;
									n.str[0] = p.str[p.size - 1 - index];
									n.next( p.nextChild(p.size - 1 - index));
									
									if(p == head)
									{
										head = n;
									}
									else{
										raxItem item = ts[$ - 2];
										item.n.nextChild(item.index , n);
									}
									
									raxNode.Free(h);
									raxNode.Free(p);
									numnodes -= 1;
									log_info("#####r314");
							}

						}
						//		#2 当['xyz'] 的size > 2时
						//			 (A)								(A)
						//			  |					A+'y'			 |
						//			['xyz']			----------->		['xz']
						//			 / |  \								/ \
						//			(C) () (D)						  (C) (D)
						//
						//
						//

						else if(p.size > 2){

							bool hasdata = p.iskey && !p.isnull;
							raxNode *u = raxNode.New(p.size - 1, hasdata);
							u.iskey = p.iskey;
							if(hasdata)
							{
								u.value = p.value;
							}

							log_info("index " , index , " " , p.size);
						
							if( index == 0)
							{
								memcpy(u.str , p.str + 1 , p.size - 1 );
							}
							else if(index == p.size - 1)
							{	
								memcpy(u.str , p.str , p.size - 1);
							}
							else
							{
								memcpy(u.str , p.str  , index);
								memcpy(u.str + index  , p.str + index + 1, p.size - index -1);
							}

							for( uint i , j  = 0 ; i < p.size ; )
							{
								if( i != index)
									u.orgin[j++] = p.orgin[i++];
								else
									i++;
							}

							if(p == head)
							{
								head = u;
							}
							else{
								raxItem item = ts[$ - 2];
								item.n.nextChild(item.index , u);
							}


							raxNode.Free(h);
							raxNode.Free(p);
							numnodes--;
							log_info("#####r32");
						}
					}
				}
				// h.size > 0
				else{
					//	#4 节点是压缩节点 ， 则合并
					//			  (A)								(A + 'test')
					//				|								 	|
					//			('test')		- 'test'				(B)
					//			   |
					//			  (B)		----------->      
					//
					//
					//	#5 只是去掉一个值。

					if(h.iscompr && p.iscompr)
					{
						bool hasdata = p.iskey && !p.isnull;
						raxNode *u = raxNode.NewComp(p.size + h.size ,  hasdata);
						u.iskey = p.iskey;
						if(hasdata)
						{
							u.value = p.value;
						}

						memcpy(u.str , p.str , p.size);
						memcpy(u.str + p.size , h.str , h.size);
						u.next(h.next);
						if(p == head)
						{
							head = u;
						}
						else
						{
							raxItem item = ts[$ - 2];
							item.n.nextChild(item.index , u);
						}
						numnodes--;
						raxNode.Free(p);
						raxNode.Free(h);
						log_info("#####r4");
					}
					else{
						log_info("#####r5");
					}

				}


				return true;			
			}
			else{
				log_error(cast(string)s , " is not key " , getStr(h));
				return false;
			}
		}
	
	}

	//insert
	int Insert(const ubyte[] s , void *data )
	{
		raxNode *h = head;
		raxNode *p = head;
		raxItem [] ts;
		uint index = 0;
		uint splitpos = 0;
		numele++;
		uint last = find(s , h , p , index , splitpos , ts);

		log_info("find " ,cast(string)s , " last ",  last , " split " , splitpos ," index " , index);

		//没有找到该s.
		if (last > 0)
		{
			// #1 如果该树是空树.
			//
			//				'test'
			//		（） ----------->（'test'）
			//							 |	
			//							()
			//							
			if(p.size == 0)
			{
				raxNode *n = raxNode.NewComp(cast(uint)s.length , false);
				memcpy(n.str , s.ptr , s.length);

				p = raxNode.RenewComp(p , 0 , true);
				p.iskey = true;
				p.value = data;

				n.next = p;
				head = n;

				numnodes++;

				log_info("####1");
			}
			else
			{
					
					// #2 直到匹配到叶子节点，都没有匹配到，必须往该叶子节点后面加剩余的字符。
					//				'tester'
					//	("test") -------->	("test")
					//		|					|
					//		()				  ("er")
					//							|
					//							()
					if(h.size == 0)
					{
						//1 new comp node
						raxNode *n = raxNode.NewComp(last , true);
						memcpy(n.str , s[ $ - last .. $].ptr , last);
						n.iskey = true;
						n.value = h.value;

						h.value = data;
			
						n.next = h;
						p.nextChild(index , n);
			
						numnodes++;

						log_info("####2");
					}
					//	#3	匹配到压缩节点，1 必须截断前部分。2 取原字符及压缩节点匹配字符构成 两个字符的 非压缩节点。 
					//			3 非压缩节点 两个子节点 分别指向 截断后半部分 及 原字符后半部分
					//
					//				'teacher'
					//	('test')---------------->('te')
					//		|						|
					//		(x)					  ['as']	u2
					//							   / \	
					//					u4 ('cher')  ('t') u3
					//						   /		\
					//					  u5 ()			(x)
					//
					else if(h.iscompr) {

						raxNode *u1;

						auto u2 = raxNode.New(2 , false);
						u2.str[0] = s[$ - last];
						u2.str[1] = h.str[splitpos];
						numnodes++;

						bool hasvalue = h.iskey && !h.isnull;
						if( splitpos > 0)
						{
							u1 = raxNode.NewComp(splitpos , hasvalue);
							memcpy(u1.str , h.str , splitpos);
							u1.iskey = h.iskey;
							if(hasvalue)
								u1.value = h.value;
							numnodes++;
						}
						else{
							u1 = u2;
							u1.iskey = h.iskey;
							if(hasvalue)
								u1.value = h.value;
						}


						uint u3_len = h.size - splitpos - 1;
						raxNode *u3;
						bool bcombine = false;
						if( u3_len > 0 )
						{
							//combin
							if(h.next.size > 0 && h.next.iscompr && !h.next.iskey)
							{
								u3 = raxNode.NewComp(u3_len + h.next.size , h.next.iskey && !h.next.isnull);
								memcpy(u3.str , h.str + splitpos + 1 , h.size - splitpos -1);
								memcpy(u3.str + h.size - splitpos - 1 , h.next.str , h.next.size);
								numnodes++;
								bcombine = true;

							}
							else
							{
								u3 = raxNode.NewComp(h.size - splitpos - 1 , false);
								memcpy(u3.str , h.str + splitpos + 1 ,h.size - splitpos -1);
								numnodes++;
							}
						}
						else
						{
							u3 = h.next;
						}
						

						//4
						uint u4_len = last - 1;
						raxNode *u4;
						
						//5
						auto u5 = raxNode.NewComp(0 , true);
						u5.iskey = true;
						u5.value = data;
						numnodes++;

						if(u4_len > 0)
						{		
							u4 = raxNode.NewComp(last - 1, false);
							memcpy(u4.str  , s.ptr + s.length - last + 1 , last - 1);
							numnodes++;
						}
						else{
							u4 = u5;
						}
						
						//relation
						if(u4_len > 0)
							u4.next = u5;

						if(bcombine)
						{
							u3.next = h.next.next;
							raxNode.Free(h.next);
							numnodes--;
						}
						else if( u3_len > 0)
						{
							u3.next = h.next;
						}	 	

						u2.nextChild(0 , u4);
						u2.nextChild(1 , u3);
						
						if(splitpos > 0)
							u1.next = u2;

						p.nextChild(index , u1);

						if( h == head)
							head = u1;
							
						raxNode.Free(h);
						numnodes--;

						log_info("####3");

				}
				// 	#4	都不匹配非压缩节点的任何子节点 1 增加该字符 2 截断原字符
				//	
				//					 'beer'				
				//			["tes"]	--------->	['tesb']
				//			/ / \ 				/ / \  \
				// 		  () () ()             () () () ('eer')
 				//											\
				//											()
				else{	

					bool hasdata = !h.isnull && h.iskey;
					auto i = raxNode.New( h.size + 1 , hasdata);
					i.iskey = h.iskey;
					i.isnull = h.isnull;
					if(hasdata)
					{
						h.value = i.value;
					}

					numnodes++;
					memcpy(i.str ,  h.str, h.size );
					i.str[h.size] = s[$ - last];
					memcpy(i.str + i.size  , h.str + h.size , h.size * (raxNode *).sizeof);


					auto u1_len = last - 1;
					raxNode *u1;


					auto u2 = raxNode.NewComp(0 , true);
					u2.value = data;
					u2.iskey = true;
					numnodes++;
					if( u1_len > 0)
					{
						u1 = raxNode.NewComp(u1_len , false);
						memcpy(u1.str , s.ptr  + s.length - last + 1  , u1_len);
						numnodes++;
						u1.next = u2;
					}
					else
					{
						u1 = u2;
					}

					i.nextChild(h.size , u1);
					p.nextChild(index , i);

					if(h == head)
						head = i;
					raxNode.Free(h);
					numnodes--;
					log_info("####4");
				}
			}

		}else{
			//	#5	完全匹配，只要改个值 即可。
			//							'te'
			//				('te')	------------->	 the same
			//				  |
			//				['as']
			//				 /  \
			//		  ('cher')  ('t')
			//			 |		  |
			//			()		 ()
			if(splitpos == 0)
			{
				bool hasdata = (h.iskey && !h.isnull);
				if(hasdata) {
					
					h.value = data;
					if(h.iskey)		//replaced
						numele--;
				}
				else{
					raxNode *u;
					if(h.iscompr)
						u = raxNode.RenewComp(h , h.size , true);
					else
						u = raxNode.Renew(h , h.size ,true);
					u.value = data;
					u.iskey = true;
					p.nextChild(index , u);
				}

				log_info("####5");

			}
			//	#6	完全匹配压缩节点前半部分。 分割即可。
			//					'te'
			//	('test')	--------->		('te')
			//		|						  |
			//	   (x)						('st')
			//								  |
			//								 (x)
			//
			else if(h.iscompr) {


				bool hasdata = (h.iskey && !h.isnull);
				auto u1 = raxNode.NewComp(splitpos , hasdata);
				memcpy(u1.str , h.str , splitpos);
				u1.iskey = h.iskey;
				if(hasdata)
					u1.value = h.value;
				numnodes++;
			
				auto u2 = raxNode.NewComp(h.size - splitpos , true);
				memcpy(u2.str , h.str + splitpos , h.size - splitpos);
				u2.iskey = true;
				u2.value = data;
				numnodes++;
				u2.next = h.next;


				u1.next = u2;

				raxNode.Free(h);
				numnodes--;
				if(h == head)
				{
					head = u1;
				}
				else{
					p.nextChild(index , u1);
				}

				log_info("####6");
			}
		}

		return 0;
	}

	//remove

	//find
	uint find(const ubyte[] s , ref raxNode *r , ref raxNode *pr , ref uint index  , ref uint splitpos ,ref raxItem[] ts)
	{
		//find it

		if ( s == null)
		{	
			return 0;
		}

		if( r.size == 0)
		{	
			return cast(uint)s.length;
		}
			
		if ( r.iscompr )	//is compr
		{
			char *p = r.str;
			uint i = 0;
			for( i = 0 ; i < r.size && i < s.length ; i++)
			{
				if(p[i] != s[i])
					break;
			}


			if( i == r.size)
			{	
				pr = r;
				r = r.next;
				index = 0;
				raxItem item;
				item.n = pr;
				item.index = index;
				ts ~= item;
				return find(s[(*pr).size .. $] , r , pr, index , splitpos , ts);
			}
			else 
			{
				splitpos = i;
				return cast(uint)s.length - i;
			}
		}
		else {

			char *p = r.str;
			char *end = r.str + r.size;
			while(p != end)
			{
				if( *p == s[0])
					break;
				p++;
			}


			uint i = cast(uint)(p - r.str);
			if( p == end)
			{	
				splitpos = i;
				return cast(uint)s.length;
			}
			else
			{
				pr = r;
				index = i ;
				r = r.nextChild(index);	
				raxItem item;
				item.n = pr;
				item.index = index;
				ts ~= item;
				return find(s[1 .. $] , r , pr , index , splitpos , ts);
			}
		}

	}


	string getStr(raxNode *h)
	{
		string str;
		for(uint i = 0 ; i < h.size ; i++)
			str ~= h.str[i];
		return str;
	}


	void Recursiveshow(raxNode *n , int level)
	{
	
		show(n , level);

		if(n.size == 0)
			return ;
			
		if(n.iscompr)
		{
			Recursiveshow(n.next , ++level);
		}
		else
		{
			++level;
			for(uint i = 0 ; i < n.size ; i++)
			{	
				Recursiveshow(n.nextChild(i) , level);
			}
		}
	}

	void show(raxNode *n , int level)
	{

		for(uint i = 0 ; i < level ; i++)
			write("\t");

		write("key:" , n.iskey  , n.iscompr ? " (" : " [");

		for(uint i = 0 ; i < n.size ; i++)
			write(n.str[i]);

		write(n.iscompr ? ") ":"] " ,  (n.iskey && !n.isnull)?n.value:null , "\n");
	}

	void show()
	{
		raxNode *p = head;
		writef("numele:%d numnodes:%d\n" , numele , numnodes);


		Recursiveshow(p ,0);

		writef("\n");
	}


private:


};








unittest{

	void test1()
	{
		rax *r = rax.New();
		void *p1 = cast(void *)0x1;
		void *p2 = cast(void*)0x2;
		void *p3 = cast(void *)0x3;
		void *p4 = cast(void *)0x4;
		void *p5 = cast(void *)0x5;
		void *p6 = cast(void *)0x6;
		void *p7 = cast(void *)0x7;
		void *p8 = cast(void *)0x8;
		void *p9 = cast(void *)0x9;
		void *p10 = cast(void *)0x10;
		void *p11 = cast(void *)0x11;
		void *p12 = cast(void *)0x12;
		void *p13 = cast(void *)0x13;
		void *p14 = cast(void *)0x14;
		void *p15 = cast(void *)0x15;
		void *p16 = cast(void *)0x16;
		void *p17 = cast(void *)0x17;
		void *p18 = cast(void *)0x18;
		void *p19 = cast(void *)0x19;
		void *p20 = cast(void *)0x20;
		void *p21 = cast(void *)0x21;
		void *p22 = cast(void *)0x22;

		r.Insert(cast(ubyte[])"test" , p1);
		r.Insert(cast(ubyte[])"tester" , p2);
		r.Insert(cast(ubyte[])"teacher" , p3);
		r.Insert(cast(ubyte[])"teachee" , p4);
		r.Insert(cast(ubyte[])"testee" , p5);

		r.Insert(cast(ubyte[])"testor" , p6);
		r.Insert(cast(ubyte[])"tech" , p7);
		r.Insert(cast(ubyte[])"teck" , p7);
		r.Insert(cast(ubyte[])"tea" , p8);
		r.Insert(cast(ubyte[])"tes" , p9);
		r.Insert(cast(ubyte[])"teache" , p10);

		r.Insert(cast(ubyte[])"teach" , p11);
		r.Insert(cast(ubyte[])"t" , p12);
		r.Insert(cast(ubyte[])"tttttttt" , p13);
		r.Insert(cast(ubyte[])"1" , p13);
		r.Insert(cast(ubyte[])"t2ttt4tttt" , p14);
		r.Insert(cast(ubyte[])"tt3t4ttttt" , p15);

		r.Insert(cast(ubyte[])"abcd" , p16);
		r.Insert(cast(ubyte[])"dsdas" , p17);
		r.Insert(cast(ubyte[])"test" , p18);
		r.Insert(cast(ubyte[])"tea1" , p19);
		r.Insert(cast(ubyte[])"tea3" , p20);


		r.Insert(cast(ubyte[])"te4a" , p21);
		r.Insert(cast(ubyte[])"t2ttt4t" , p22);



	
		r.show();

		r.Remove(cast(ubyte[])"test" );
		r.Remove(cast(ubyte[])"tester" );
		r.Remove(cast(ubyte[])"teacher" );
		r.Remove(cast(ubyte[])"teachee" );
		r.Remove(cast(ubyte[])"testee" );

		r.Remove(cast(ubyte[])"testor" );
		r.Remove(cast(ubyte[])"tech" );
		r.Remove(cast(ubyte[])"teck" );
		r.Remove(cast(ubyte[])"tea" );
		r.Remove(cast(ubyte[])"tes" );
		r.Remove(cast(ubyte[])"teache");
	
		r.Remove(cast(ubyte[])"teach" );
		r.Remove(cast(ubyte[])"t" );
		r.Remove(cast(ubyte[])"tttttttt" );
		r.Remove(cast(ubyte[])"1" );
		r.Remove(cast(ubyte[])"t2ttt4tttt" );
		r.Remove(cast(ubyte[])"tt3t4ttttt");

		r.Remove(cast(ubyte[])"abcd" );
		r.Remove(cast(ubyte[])"dsdas" );
		r.Remove(cast(ubyte[])"tea1" );
		r.Remove(cast(ubyte[])"tea3" );

		r.Remove(cast(ubyte[])"te4a" );
		r.Remove(cast(ubyte[])"t2ttt4t" );

		r.show();

	}

	void test2()
	{
		rax *r = rax.New();
		r.show();
		void *p1 = cast(void *)0x1;
		void *p2 = cast(void*)0x2;
		r.Insert(cast(ubyte[])"test" , p1);
		r.show();
		r.Insert(cast(ubyte[])"tester" , p2);
		r.show();
		r.Remove(cast(ubyte[])"test" );
		r.show();
		r.Remove(cast(ubyte[])"tester");
		r.show();
	}

	void test3()
	{
		rax *r = rax.New();
		void *p1 = cast(void *)0x1;
		void *p2 = cast(void*)0x2;
		void *p3 = cast(void *)0x3;
		void *p4 = cast(void *)0x4;
		r.Insert(cast(ubyte[])"te" , p1);
		r.Insert(cast(ubyte[])"test" , p2);
		r.Insert(cast(ubyte[])"tester" , p3);
		r.Insert(cast(ubyte[])"testering" , p4);
		r.show();
		r.Remove(cast(ubyte[])"tester");
		r.show();
		r.Remove(cast(ubyte[])"te");
		r.show();
		r.Remove(cast(ubyte[])"test");
		r.Remove(cast(ubyte[])"testering");
		r.show();
	}

	void test4(){

		rax *r = rax.New();
		void *p1 = cast(void *)0x1;
		void *p2 = cast(void*)0x2;
		void *p3 = cast(void *)0x3;
		void *p4 = cast(void *)0x4;
		void *p5 = cast(void *)0x5;
		void *p6 = cast(void*)0x6;
		void *p7 = cast(void *)0x7;
		void *p8 = cast(void *)0x8;

		r.Insert(cast(ubyte[])"tt" , p1);
		r.Insert(cast(ubyte[])"t1" , p2);
		r.Insert(cast(ubyte[])"tea" , p3);
		r.Insert(cast(ubyte[])"test" , p4);
		r.Insert(cast(ubyte[])"tester" , p5);
		r.Insert(cast(ubyte[])"fuck" , p6);
		r.Insert(cast(ubyte[])"fucking" , p7);
		r.Insert(cast(ubyte[])"you" , p8);


		r.Remove(cast(ubyte[])"tt" );

		r.Remove(cast(ubyte[])"t1" );
	
	
		r.Remove(cast(ubyte[])"tea");
	
		r.Remove(cast(ubyte[])"test" );



		r.Remove(cast(ubyte[])"tester" );
		r.Remove(cast(ubyte[])"fuck" );

		r.Remove(cast(ubyte[])"fucking" );
		r.show();
		r.Remove(cast(ubyte[])"you");
		r.show();

	}

	void test5()
	{
		string toadd[] = ["alligator","alien","baloon","chromodynamic","romane","romanus","romulus","rubens","ruber","rubicon","rubicundus","all","rub","ba"];
		rax *r = rax.New();
		foreach( i ,s ; toadd)
		{
			r.Insert(cast(ubyte[])s , cast(void *)i);
		}
	
		foreach(s ; toadd)
		{
			r.Remove(cast(ubyte[])s);
		}
		r.show();
	}

	void test7()
	{
		string toadd[] = ["alligator","alien","baloon","chromodynamic","romane","romanus","romulus","rubens","ruber","rubicon","rubicundus","all","rub","ba"];
		rax *r = rax.New();
		foreach( i ,s ; toadd)
		{
			r.Insert(cast(ubyte[])s , cast(void *)i);
		}

		r.show();

		r.Remove(cast(ubyte[])toadd[13]);
		r.Remove(cast(ubyte[])toadd[12]);
		r.Remove(cast(ubyte[])toadd[11]);

		r.Remove(cast(ubyte[])toadd[8]);
		r.Remove(cast(ubyte[])toadd[7]);



		r.Remove(cast(ubyte[])toadd[10]);
		r.Remove(cast(ubyte[])toadd[9]);

		r.Remove(cast(ubyte[])toadd[6]);
		r.Remove(cast(ubyte[])toadd[5]);
		r.Remove(cast(ubyte[])toadd[4]);

		r.Remove(cast(ubyte[])toadd[3]);
		r.Remove(cast(ubyte[])toadd[2]);
		r.Remove(cast(ubyte[])toadd[1]);
		r.Remove(cast(ubyte[])toadd[0]);
		r.show();
	}

	void test6()
	{
		string origin = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                      "abcdefghijklmnopqrstuvwxyz"
				"0123456789";



		import std.random;

			string[] keys;
			uint num = 500;

			for(uint j = 0 ; j < num ; j++)
			{
				uint len = uniform(1 , 16);
				string key;
				for(uint i = 0 ; i < len ; i++)
				{
					ulong index = uniform(0 , origin.length);
					key ~= origin[index];
				}
				keys ~= key;
			}


			foreach(k ; keys)
			{
				writeln(k);
			}



			rax *r = rax.New();
			foreach(i , k ; keys)
				r.Insert(cast(ubyte[])k , cast(void *)i);

			foreach(k ; keys)
			{
				r.Remove(cast(ubyte[])k);
			}

			r.show();


	}

	void test8()
	{
		string[] keys = ["i5hXOjIMfMIDFOV",
			"8S42FOb8QCi6Z",
				"0m4DruYKd",
				"kWohExvd",
				"zKhRdcjc8OX",
				"SD",
				"YvUqR",
				"V3SfkG",
				"OsJota6Ty0B9",
				"2naBFIRu501e97B",
				"lniA8Rc4Wrd",
				"X2NLf7DhveVp5",
				"0KwThA5op15TUf",
				"UV1Dle",
				"0HGHlDA",
				"Ijb",
				"D4jUBFEP",
				"9",
				"4",
			"B0UWW25Hag6QQCW"];

		rax *r = rax.New();
		foreach(i , k ; keys)
			r.Insert(cast(ubyte[])k , cast(void *)i);
		
		foreach(k ; keys)
		{
			r.Remove(cast(ubyte[])k);
		}
		
		r.show();


	}

	void test10()
	{
		string[] keys = ["ECSQRpibXomv5rq",
			"1bbE071jrvKI",
			"MFecoeDB",
			"kLvebdY",
			"R",
			"8k81",
			"nI8oknzTJcqAiZW",
			"8cp",
			"nrwzo91l",
			"kKJGT2oscO",
			"CBhyBazS",
			"kwt",
			"EjeUZ",
			"SynyBzDe2vPuwdH",
			"DvXUh3BA42dbjCu",
			"TAv0UNQCIZNwv",
			"Zp",
			"7FLCzmo6vMb",
			"KP3uOonF1",
			"TiYcUpXtDR",
			"NxtKETAN2urK",
			"3Zd1KgMS6xJx",
			"n1B",
			"9RGdQF13up5M4HA",
			"IooTA",
			"F0huIEQ",
			"4RH",
			"Zr4K5jsuOWST9w",
			"LmbJ0NjvNv7a",
			"z1uRCTLXpugvca6",
			"sqPb",
			"N49x2jni",
			"2756L8cw9Ob5a0",
			"trX9XpX",
			"X9eKdZ8oYrfMU",
			"93rUfmaOH",
			"fOv291z",
			"V",
			"9kntLyBHgzl",
			"koLVQqkeiz2h",
			"A80ewI4d0d",
			"wR",
			"zfttu7DB",
			"JmBSB0p",
			"IcvPYBD",
			"3tiF5d8",
			"B",
			"R6",
			"0nKzR7tS",
			"3ljmGUfzyoI",
			"8VrwcxGhYc",
			"iKR5ecyfH9sSyK",
			"nczAF6BnQE4xqw6",
			"mnISmhV",
			"7mGn5WQFK",
			"w6hO",
			"PiDQ7Q",
			"i9",
			"fGWCzznQbs1",
			"2EAFv3y3",
			"9HvLYu",
			"rD7E",
			"G16FR",
			"rOSFSIPDuYfmaPY",
			"rcxdRTT5VBpcOT",
			"pyK2ISwdETcGN8",
			"cJdjqdIcUTc2",
			"XPq3Kp79eTi",
			"77fVUfvws3qrG",
			"BwjxYrjY5Kf3",
			"U4AvVBckgCTauJ",
			"RB9jrfrlID",
			"1hBz7PxL6YeTAPm",
			"oNO1teCYQx",
			"Fen8YD58MzQN",
			"dVW2o0Y6f",
			"g1O",
			"hAl8kCMJNBBn2",
			"D5zwIjXA1aV8",
			"2i8PvR5RhxAwF",
			"lFZulL",
			"04xKn",
			"njypIpY9I5",
			"sFH9fzV",
			"2GW4mUt",
			"8IV64MN23OiHC",
			"AarhGRUWWK3kN",
			"AIXM",
			"NLL9jZv",
			"Iqkq6EkgHma98",
			"Vrru0yrcQYlU",
			"WiAL4vt",
			"OEL9ialUFMT",
			"tFD",
			"oGwL19eNeBz",
			"N6ykO2Yj2RHeo",
			"dg5Y5hS4Be",
			"RBsMsQZ4RaV",
			"FdDsY",
			"YkJraQqSWDvR4S",
			"Ngq8GQBJo07",
			"G0FTXgxdSmf",
			"u76wMYe8",
			"Vz4DqYHXUz7o",
			"w",
			"RP44zmMDDm",
			"JLvcVRjaAWJ1",
			"hy2tvs",
			"T3B46dPAhjGzk",
			"i",
			"vslKX622aGtN",
			"zoBQ8Z2G",
			"v3RgEwi7kSvgI2V",
			"g86",
			"xZb3qUoYsRE",
			"z",
			"xb",
			"TcESY",
			"7LxJVzzdYubvxeI",
			"KVSJ0j",
			"cwW9F",
			"GGzm3SWIvmhGMQ",
			"ETZf8Vhm8bRfI",
			"Oup9",
			"6QhnZkw8A",
			"366",
			"tN",
			"brOipdJe2sFSeL",
			"XGOO",
			"XXGr1y3Bd",
			"Co",
			"NwilrH",
			"bzM7lp8zRt9rQaE",
			"PjsOzB",
			"qnjxy9ZbTM",
			"RcyW55l7VLdYb",
			"vr9Acz",
			"wtToW6Mvl9fOxuW",
			"yTQoKgD0B8",
			"RbPogDojYe0",
			"v5D95f8TK0Tsx",
			"8a9DQRkRyOgWtK8",
			"kRo",
			"KMT5sl7VimM4dH",
			"mLySBS",
			"Se7yGK2ZBe",
			"7S4wAEDQuzB54",
			"g3QBjNUne7pr",
			"zxi",
			"91UePPy",
			"8SRH89YurP",
			"7",
			"WCAt",
			"tylmL",
			"rjYGdk91QXEr",
			"eNJe",
			"lTf2k",
			"ktPjywE97F",
			"w6S",
			"bh",
			"iJVzhVnNS",
			"ABWcgg",
			"tYkVZS5IhuIep90",
			"VXc9cM",
			"K1c8oqNIunI",
			"2jhAfA",
			"r",
			"9nCvR9bFpnqW",
			"wamzbsHzHj",
			"rrybD",
			"nxiyKZnQ",
			"D0TSASaY",
			"t",
			"6yNnluu0AIN",
			"TwhZssAR",
			"SHP",
			"AsphT",
			"MEfx",
			"X9",
			"wA4kZ57GD2",
			"o7tZv79uGV3",
			"BreYd7X",
			"9RA7",
			"egGCRJ",
			"uwIIXDf1cSl4",
			"cA4j",
			"S",
			"8NFivJLuk",
			"3wMKI8cWlJGR8",
			"Jek1uhLFKtcJO",
			"natM3k",
			"ALGa",
			"xOI0S",
			"B5HB",
			"VowSQ4MqryiV",
			"97e",
			"yyEGJA",
			"ubdgd2H",
			"RMQVKmbDfZSmTo",
			"OgwO1u",
			"S",
			"F5bk4kem",
			"Jt",
			"Tvh8sbS9jd",
			"H",
			"hrjj1BErxIo",
			"iXU",
			"EunWhhURg4",
			"PFowgAyZPjF9Y",
			"XO",
			"m81BdnqaqhmwT",
			"YB5t",
			"KcZtpgnLhmHS",
			"pWg4Rem0fyf",
			"yZtrgV",
			"7YyDU",
			"eCmL3",
			"puk2McBU10KJ",
			"OeB0WA",
			"1pjwGLh",
			"KQ6nbBk6iFpVbg",
			"Lqko",
			"65enAW4g6",
			"X4i5",
			"x73gwC77vdVA",
			"BXyqe7zJliVYPX",
			"CS5PQi",
			"hMLivjDoscyj",
			"s92tvj4ZuLnfJVu",
			"4JkWxTa6",
			"SnTwdqLVsxw",
			"ou7eL5ziK9o2a",
			"VeJHyAy",
			"q3CAWDh5gptX",
			"Nge9aE",
			"wn",
			"swqfCUbHa9sD",
			"VPkYG6olj",
			"x5RwE",
			"LR0wir",
			"nkWJgoPfeW9Ubag",
			"taEUo",
			"QgfkZUq",
			"F",
			"H",
			"j4Ak6F0N1b8n",
			"9PZ",
			"j",
			"0skRT3",
			"GQ",
			"7",
			"Z8Mj0aWL9Ws8ij",
			"ybku9ShkImY",
			"55QAM7QBz6LUV",
			"OeQabmey",
			"ATpNWag4e39",
			"rhtc5CT5d",
			"D",
			"eDmaMUlK",
			"Mlp02waKh5yomH",
			"zSHKnjB9MD3",
			"f",
			"1o6",
			"9hE",
			"MGBztWwX7mR9mkd",
			"IYqX2wZ68pnbSrg",
			"PMpaylbUoBXhsg",
			"A",
			"y6KSYhob0Jiq",
			"24OmSH0",
			"ruu1edaMo",
			"z1Cn659",
			"sLQU",
			"62MaLtv",
			"Q0q6U0yJqhO",
			"iU",
			"U",
			"3p",
			"Nplg4QegzppF",
			"K20yeBgK",
			"oC8",
			"FR1IBdT7fQE95D",
			"i4",
			"34xObz9UH0gV",
			"WaibCXIdqa2V",
			"0dhOVb",
			"xYcES",
			"2Dsxz0Itiz304K",
			"aqzkiYcqjztW",
			"9ZGHkk8",
			"DICO7A8lK",
			"guzcsbV",
			"cImTwZ",
			"gae1QbXxTF",
			"DpckU0Tul",
			"wWw01p",
			"dyhu",
			"p1xEUKgmMtRGhCB",
			"ieISmFzrfSup698",
			"1nBzbEVDXH7xQ",
			"q",
			"Uq",
			"XD6uTAjibfF",
			"mX9zkk9nsDJA",
			"2MHdv",
			"akHIxoGvcZ34DH",
			"Qnsa",
			"tTVAJfu",
			"gIY1im",
			"qWShC1Z",
			"5Zz2fT",
			"dc7LqELAAefB8",
			"zDK1",
			"d5Nk4Y6Udi4y3FU",
			"cWWqF",
			"q9",
			"qCQTH2jCkArw",
			"L",
			"YeFXiVi5o",
			"F",
			"OezeJK4OLlxvo",
			"2mx3t4S0FGD9fr",
			"pQ",
			"JovDWkJYlOAIn",
			"pR4hzEgvHJKCMGn",
			"AevM",
			"R6Evya",
			"lEJhU0ZF0GTWMy",
			"Cpe",
			"fiAG3ag4FlZln",
			"qUr",
			"wWzwXOmZORl3",
			"YYsdlQK8Gwt",
			"1CrsF5y2",
			"m",
			"jauZE093S4",
			"HC4X2qZSSnMS05",
			"2",
			"o7qNAIjRCEWx",
			"yHWIvL4",
			"l",
			"m6BO4tGNL5JEgPs",
			"You1RIZtDe0PPgq",
			"eTdyfHOrx",
			"bxO",
			"3cLt1RiDc906Ec",
			"iDzARFL",
			"7Ic19",
			"pURGQID",
			"cZNlVu4dATo",
			"XqGPtLuNE41qw0j",
			"OZ",
			"vFQP8W4iQGw7mG",
			"7vx6Z5wjVZlf2",
			"Jwm9kv",
			"p1WboQd0rv82I",
			"RtuNmr",
			"EtWHHZd5TnQ",
			"AwzVzoXyrlLc6w",
			"LzzKmMFsf86ezc",
			"EjWPyQSf5yPxfMT",
			"okNRXP",
			"j7xUK",
			"g",
			"onqS",
			"tmcJggr",
			"KxHs",
			"7Q5Pv1DBU",
			"ucwm",
			"n1",
			"Aj2pDPrif5FGv6",
			"yu3NbHpnJ",
			"ikdT",
			"jqw9N",
			"HcuUk9o",
			"OvRjDnt",
			"dzWUoWtqk",
			"PGHmK",
			"mt",
			"iI7Cib",
			"pR",
			"W3rjl09C",
			"cZSUZe8jzn",
			"eWa",
			"S",
			"xEpvTOMn7Yvs",
			"hVKZCX4eIVVzWx",
			"tOIZmE4Q",
			"pjBaY",
			"YUbvAtYJUQ",
			"uPJ08Qx6F",
			"2bMHEzlldQVFwG2",
			"v",
			"lpSEOYFf",
			"o4",
			"3tk4HSVrYHp1",
			"IRRrbzgz8PN9",
			"9PDbZWRljhnbl",
			"ma",
			"zSJ28Si0hp",
			"I3AzeRdqaOcF",
			"7w713dC94WPq",
			"plTLYvdub0Awhc",
			"8b9PATMwK",
			"kMmHJDDjUC",
			"WAYm",
			"m82vKWF4fwLY6E",
			"RQ5sRqgqhR",
			"LvvpOtSCJstjYcS",
			"wqlnRVbW8dX",
			"0H",
			"cjkZ7GZKR22Hi",
			"CBlLxMW44jaY9NW",
			"POf0T7Mm79Vjzzc",
			"5n5AdB6ic2Bo",
			"z2GoHQh4S6V5GK",
			"Ku",
			"T1ToBN",
			"LvpWahMZ02",
			"3szA",
			"xh",
			"MQEmBMWa",
			"itWlifbufpWT2",
			"Q30WaBlKZEf2yze",
			"Q3",
			"vX4sEbN",
			"GWumssqaq6c",
			"R9KvD0b",
			"rlY4",
			"x2fSmtaMAqvZG",
			"4lBj4",
			"i",
			"wv",
			"nm8kLY9FINiTk",
			"JfEbhHaMNp7zpvn",
			"M2A5yEU5qVY",
			"6j0",
			"FV5",
			"n4phjL5z",
			"uixUk6N2Kec",
			"wQp0",
			"jHtHq",
			"sASrke",
			"oM7jv0VAZOc",
			"bsUUBO3fI7",
			"HUEiEXceunEt",
			"KEqkDOn",
			"7OIq",
			"clp",
			"SB",
			"l6ewhctETGF36DK",
			"jC5",
			"f7xsg1N",
			"UJ",
			"KRA1R9G",
			"P2CHPFCMgA",
			"Af588aRbakmEv9y",
			"NE5XNCX6nXu9L",
			"VXsG",
			"08bjazJrcq1Z",
			"qPDpSvxrplbbrGr",
			"Mq3pl",
			"8",
			"uCw",
			"KW3QA7p",
			"b",
			"bWzupR6LMraJ",
			"TGIZ1Y8",
			"QhgeP",
			"lJmZe5mSI",
			"1wpommfdG4GKJb",
			"62nWQnjsXmBFk",
			"SCH3K",
			"P",
			"oQzDHN",
			"WQL1B",
			"H",
			"6oNfkF",
			"4LBQKqPboSCUEuJ",
			"7rNTc",
			"rFpK1",
			"QyMQZ",
			"x",
			"mb9WXc",
			"PRBEnVvOedNCZ4K",
			"vz7Cw8sM",
			"dXU9m9pgjMwgH",
			"lLFj9JIBe3VLEyS",
			"CcaJizRub3GFAj",
			"xS7wxjDieZMdxzk",
			"aS94ckc8hLT",
			"x6x",
			"53ZqAEuQbv",
			"oxn3jpeUnchIVq",
			"8yMHX1Bfn",
			"gCc",
			"QlL1s",
			"Pj8Aax",
			"Qx7mxny",
			"fokupSJ4FUJu"];

		rax *r = rax.New();
		foreach(i , k ; keys)
			r.Insert(cast(ubyte[])k , cast(void *)i);

	/*	foreach(i , k ; keys)
		{
			writeln(i);
			r.Remove(cast(ubyte[])k);
		}
		r.show();*/


		for(uint i = 0 ; i < 62 ; i++)
		{
			r.Remove(cast(ubyte[])keys[i]);
		}

		r.show();
		log_info(keys[63]);
		r.Remove(cast(ubyte[])keys[63]);
		//r.show();
		//r.Remove(cast(ubyte[])keys[100]);
		//r.Remove(cast(ubyte[])keys[101]);
		//r.Remove(cast(ubyte[])keys[102]);

		//log_info(keys[103]);
		//r.Remove(cast(ubyte[])keys[103]);
		//r.show();
		//r.Remove(cast(ubyte[])keys[104]);





	}

	void test9()
	{
		string[] keys = ["RdTKj",
			"He2Gsb",
				"Fwob",
				"t0C",
				"Su8AGYX7DmWOVO",
				"ygGPWOyUVL",
				"q2bIXzhb1sCQgDH",
				"6ihFdqa",
				"DRwOFQQ",
				"iF93hQ6xa",
				"Cmt",
				"hFPEX1ui",
				"NT",
				"w",
				"Voytvf",
				"TtlBfzGs",
				"cvKiZYoacPn",
				"JSS",
				"P2zR7J",
				"GcY",
				"Gnf",
				"kaxk",
				"FKl",
				"LTZm7oC1BtyIODT",
				"mk",
				"paFJso",
				"CrWqS5hJqo8z",
				"7WHBEeMG4HYxh",
				"pZinOgludCH",
				"SONHc",
				"k747SK8OSF",
				"0",
				"qN86QadNnGb",
				"JdICoMkuBcuK",
				"Mns9RcChdRVvwT",
				"WVSWrO",
				"R2n1TCrGaUssHT",
				"GZBHhEIev",
				"SvpbCJ",
				"lWrlE",
				"0ABichNaV5U",
				"lPox1jiF",
				"BMevwW",
				"j7",
				"Cl05e2NghjHiU31",
				"4N3MyE",
				"e2umn0Y",
				"Fd3P",
				"NRnn32q",
			"JERU"];
		rax *r = rax.New();

		r.Insert(cast(ubyte[])keys[0] , cast(void *)0);
		r.Insert(cast(ubyte[])keys[1] , cast(void*)1);
		r.Insert(cast(ubyte[])keys[2] , cast(void*)2);
		r.Insert(cast(ubyte[])keys[3] , cast(void*)3);
		r.Insert(cast(ubyte[])keys[4] , cast(void*)4);
		r.Insert(cast(ubyte[])keys[5] , cast(void*)5);
		r.Insert(cast(ubyte[])keys[6] , cast(void*)6);
		r.Insert(cast(ubyte[])keys[7] , cast(void*)7);
		r.Insert(cast(ubyte[])keys[8] , cast(void*)8);
		r.Insert(cast(ubyte[])keys[9] , cast(void*)9);


		r.Insert(cast(ubyte[])keys[10] , cast(void*)10);
		r.Insert(cast(ubyte[])keys[11] , cast(void*)11);
		r.Insert(cast(ubyte[])keys[12] , cast(void*)12);
		r.Insert(cast(ubyte[])keys[13], cast(void*)13);
		r.Insert(cast(ubyte[])keys[14], cast(void*)14);
		r.Insert(cast(ubyte[])keys[15], cast(void*)15);
		r.Insert(cast(ubyte[])keys[16], cast(void*)16);
		r.Insert(cast(ubyte[])keys[17], cast(void*)17);
		r.Insert(cast(ubyte[])keys[18], cast(void*)18);
		r.Insert(cast(ubyte[])keys[19], cast(void*)19);


		r.Insert(cast(ubyte[])keys[20], cast(void*)20);
		r.Insert(cast(ubyte[])keys[21], cast(void*)21);
		r.Insert(cast(ubyte[])keys[22], cast(void*)22);
		r.Insert(cast(ubyte[])keys[23], cast(void*)23);
		r.Insert(cast(ubyte[])keys[24], cast(void*)24);
		r.Insert(cast(ubyte[])keys[25], cast(void*)25);
		r.Insert(cast(ubyte[])keys[26], cast(void*)26);
		r.Insert(cast(ubyte[])keys[27], cast(void*)27);
		r.Insert(cast(ubyte[])keys[28], cast(void*)28);
		r.Insert(cast(ubyte[])keys[29], cast(void*)29);
	

		r.Insert(cast(ubyte[])keys[30], cast(void*)30);
		r.Insert(cast(ubyte[])keys[31], cast(void*)31);
		r.Insert(cast(ubyte[])keys[32], cast(void*)32);
		r.Insert(cast(ubyte[])keys[33], cast(void*)33);
		r.Insert(cast(ubyte[])keys[34], cast(void*)34);
		r.Insert(cast(ubyte[])keys[35], cast(void*)35);
		r.Insert(cast(ubyte[])keys[36], cast(void*)36);
		r.Insert(cast(ubyte[])keys[37], cast(void*)37);
		r.Insert(cast(ubyte[])keys[38], cast(void*)38);
		r.Insert(cast(ubyte[])keys[39], cast(void*)39);

		r.Insert(cast(ubyte[])keys[40], cast(void*)40);
		r.Insert(cast(ubyte[])keys[41], cast(void*)41);
		r.Insert(cast(ubyte[])keys[42], cast(void*)42);
		r.Insert(cast(ubyte[])keys[43], cast(void*)43);
		r.Insert(cast(ubyte[])keys[44], cast(void*)44);
		r.Insert(cast(ubyte[])keys[45], cast(void*)45);
		r.Insert(cast(ubyte[])keys[46], cast(void*)46);
		r.Insert(cast(ubyte[])keys[47], cast(void*)47);
		r.Insert(cast(ubyte[])keys[48], cast(void*)48);
		r.Insert(cast(ubyte[])keys[49], cast(void*)49);

		r.show();

		r.Remove(cast(ubyte[])keys[0]);
		r.Remove(cast(ubyte[])keys[1]);
		r.Remove(cast(ubyte[])keys[2]);
		r.Remove(cast(ubyte[])keys[3]);
		r.Remove(cast(ubyte[])keys[4]);
		r.Remove(cast(ubyte[])keys[5]);
		r.Remove(cast(ubyte[])keys[6]);
		r.Remove(cast(ubyte[])keys[7]);
		r.Remove(cast(ubyte[])keys[8]);
		r.Remove(cast(ubyte[])keys[9]);

		r.Remove(cast(ubyte[])keys[10]);
		r.Remove(cast(ubyte[])keys[11]);
		r.Remove(cast(ubyte[])keys[12]);
		r.Remove(cast(ubyte[])keys[13]);
		r.Remove(cast(ubyte[])keys[14]);
		r.Remove(cast(ubyte[])keys[15]);
		r.Remove(cast(ubyte[])keys[16]);
		r.Remove(cast(ubyte[])keys[17]);
		r.Remove(cast(ubyte[])keys[18]);
		r.Remove(cast(ubyte[])keys[19]);

		r.Remove(cast(ubyte[])keys[20]);
		r.Remove(cast(ubyte[])keys[21]);
		r.Remove(cast(ubyte[])keys[22]);
		r.Remove(cast(ubyte[])keys[23]);
		r.Remove(cast(ubyte[])keys[24]);
		r.Remove(cast(ubyte[])keys[25]);
		r.Remove(cast(ubyte[])keys[26]);
		r.Remove(cast(ubyte[])keys[27]);
		r.Remove(cast(ubyte[])keys[28]);
		r.Remove(cast(ubyte[])keys[29]);

		r.Remove(cast(ubyte[])keys[30]);
		r.Remove(cast(ubyte[])keys[31]);
		r.Remove(cast(ubyte[])keys[32]);
		r.Remove(cast(ubyte[])keys[33]);
		r.Remove(cast(ubyte[])keys[34]);
		r.Remove(cast(ubyte[])keys[35]);
		r.Remove(cast(ubyte[])keys[36]);
		r.Remove(cast(ubyte[])keys[37]);
		r.Remove(cast(ubyte[])keys[38]);
		r.Remove(cast(ubyte[])keys[39]);

		r.Remove(cast(ubyte[])keys[40]);
		r.Remove(cast(ubyte[])keys[41]);
		r.Remove(cast(ubyte[])keys[42]);
		r.Remove(cast(ubyte[])keys[43]);
		r.Remove(cast(ubyte[])keys[44]);
		r.Remove(cast(ubyte[])keys[45]);
		r.Remove(cast(ubyte[])keys[46]);
		r.Remove(cast(ubyte[])keys[47]);
		r.Remove(cast(ubyte[])keys[48]);
		r.Remove(cast(ubyte[])keys[49]);
		r.show();
	}

	//test1();
	//test4();
	//test2();
	//test3();
	//test5();
	//test7();
	//for(uint i = 0 ; i <10 ; i++)
	//	test6();
	test10();
	//test8();
	//test9();

}

